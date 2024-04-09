// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./Reentrancy.sol";

library BattleLib {
    enum BattleMode {
        THREE,
        FIVE
    }

    enum BattleStatus {
        PENDING,
        STARTED,
        ENDED
    }

    struct BattleInfo {
        address battleid;
        address owner;
        address fighter;
        address winner;
        uint256 betamount;
        BattleMode mode;
        BattleStatus status; // 0 - waiting; 1 - started; 2 - ended
        uint256 createat;
    }
}

contract BattleV2 is AccessControl, Reentrancy, EIP712 {
    address immutable GAME_MASTER;
    string private constant SIGNING_DOMAIN = "BonkBattle";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 typeHash = keccak256("Voucher(uint256 voucherid,address owner)");

    error InvalidSigner();
    /// @notice voucherid: 0 = loser; 1 = winner; 2 = draw
    struct Voucher {
        uint256 voucherid;
        address owner;
    }

    BattleLib.BattleInfo private battleinfo;
    IERC20 private token_bet;
    IERC721 private card_nft;
    mapping(address => uint256[]) private nfts;
    mapping(address => bool) private claimed;

    constructor(
        address _gm,
        address _bet_token,
        address _card_nft
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        GAME_MASTER = address(_gm);
        token_bet = IERC20(_bet_token);
        card_nft = IERC721(_card_nft);
    }

    function initBattleInfo(
        BattleLib.BattleInfo calldata _info
    ) external onlyRole(DEFAULT_ADMIN_ROLE) lock {
        require(battleinfo.owner == address(0), "already init");
        battleinfo = _info;
    }

    function getBattleInfo() public view returns (BattleLib.BattleInfo memory) {
        return battleinfo;
    }

    function getNFTs(
        address _account
    ) external view returns (uint256[] memory) {
        return nfts[_account];
    }

    function joinBattle(uint256[] calldata _tokenids) external lock {
        require(
            _tokenids.length ==
                (battleinfo.mode == BattleLib.BattleMode.FIVE ? 5 : 3)
        );
        require(battleinfo.status == BattleLib.BattleStatus.PENDING);
        if (address(msg.sender) == address(battleinfo.owner)) {
            require(battleinfo.fighter != address(0), "no fighter in battle");
            battleinfo.status = BattleLib.BattleStatus.STARTED;
        } else {
            require(battleinfo.fighter == address(0));
            battleinfo.fighter = address(msg.sender);
        }
        bool check_transfer = token_bet.transferFrom(
            msg.sender,
            address(this),
            battleinfo.betamount
        );
        require(check_transfer);
        nfts[msg.sender] = _tokenids;
        for (uint256 index = 0; index < _tokenids.length; index++) {
            card_nft.transferFrom(
                address(msg.sender),
                address(this),
                _tokenids[index]
            );
        }
    }

    function exitBattle() external lock {
        require(
            battleinfo.status != BattleLib.BattleStatus.ENDED,
            "battle ended"
        );
        require(
            msg.sender == battleinfo.owner || msg.sender == battleinfo.fighter
        );
        if (battleinfo.status == BattleLib.BattleStatus.STARTED) {
            if (battleinfo.owner == address(msg.sender)) {
                battleinfo.winner = battleinfo.fighter;
            } else if (battleinfo.fighter == address(msg.sender)) {
                battleinfo.winner = battleinfo.owner;
            }
        } else if (battleinfo.status == BattleLib.BattleStatus.PENDING) {
            battleinfo.winner = address(0);
        }

        battleinfo.status = BattleLib.BattleStatus.ENDED;
    }

    function forceStop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(battleinfo.status != BattleLib.BattleStatus.ENDED);
        battleinfo.status = BattleLib.BattleStatus.ENDED;
        battleinfo.winner = address(0);
    }

    function claim(
        Voucher calldata voucher,
        bytes memory signature
    ) external lock {
        address signer = _verify(voucher, signature);
        if (GAME_MASTER != signer) revert InvalidSigner();
        require(!claimed[voucher.owner], "claimed");
        battleinfo.status = BattleLib.BattleStatus.ENDED;
        if (voucher.voucherid == 1) {
            battleinfo.owner = voucher.owner;
            token_bet.transfer(
                address(voucher.owner),
                token_bet.balanceOf(address(this))
            );
        } else if (voucher.voucherid == 2) {
            token_bet.transfer(voucher.owner, battleinfo.betamount);
        }

        for (uint256 index = 0; index < nfts[voucher.owner].length; index++) {
            card_nft.safeTransferFrom(
                address(this),
                voucher.owner,
                nfts[voucher.owner][index]
            );
        }
        claimed[voucher.owner] = true;
    }

    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(typeHash, voucher.voucherid, voucher.owner)
                )
            );
    }

    function _verify(
        Voucher calldata voucher,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, signature);
    }
}

contract BattleFactoryV2 is AccessControl {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    address[] private battleList;
    mapping(address => address[]) private battleOfOwner;
    IERC20 public token_bet;
    IERC721 public card_nft;
    address public gameMaster;
    event BattleCreate(address battleid, address owner);
    constructor(address _bet_token, address _card_nft) {
        token_bet = IERC20(address(_bet_token));
        card_nft = IERC721(address(_card_nft));
        gameMaster = address(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
    }

    function createBattle(uint256 _mode, uint256 _bet_amount) external {
        BattleLib.BattleInfo[] memory myBattles = getBattleByOwner(msg.sender);
        for (uint256 index = 0; index < myBattles.length; index++) {
            BattleLib.BattleInfo memory iBattle = myBattles[index];
            require(
                iBattle.status == BattleLib.BattleStatus.ENDED,
                "your battle not end yet"
            );
        }
        BattleLib.BattleMode __mode;
        if (_mode == 0) {
            __mode = BattleLib.BattleMode.THREE;
        } else {
            __mode = BattleLib.BattleMode.FIVE;
        }
        BattleV2 mybattle = new BattleV2(
            gameMaster,
            address(token_bet),
            address(card_nft)
        );
        bool check_transfer = token_bet.transferFrom(
            msg.sender,
            address(mybattle),
            _bet_amount
        );
        require(check_transfer, "transfer token to battle failed");
        BattleLib.BattleInfo memory createdBattle = BattleLib.BattleInfo(
            address(mybattle),
            address(msg.sender),
            address(0),
            address(0),
            _bet_amount,
            __mode,
            BattleLib.BattleStatus.PENDING,
            block.timestamp
        );
        mybattle.initBattleInfo(createdBattle);
        battleOfOwner[msg.sender].push(address(mybattle));
        battleList.push(address(mybattle));
        emit BattleCreate(address(mybattle), address(msg.sender));
    }

    function getBattleByOwner(
        address _owner
    ) public view returns (BattleLib.BattleInfo[] memory) {
        uint256 len = battleOfOwner[_owner].length;
        BattleLib.BattleInfo[] memory results = new BattleLib.BattleInfo[](len);
        for (uint256 index = 0; index < len; index++) {
            address _battleid = battleOfOwner[_owner][index];
            results[index] = BattleV2(_battleid).getBattleInfo();
        }
        return results;
    }

    function getAllBattle()
        public
        view
        returns (BattleLib.BattleInfo[] memory)
    {
        uint256 len = battleList.length;
        BattleLib.BattleInfo[] memory results = new BattleLib.BattleInfo[](len);
        for (uint256 index = 0; index < len; index++) {
            address _battleid = battleList[index];
            results[index] = BattleV2(_battleid).getBattleInfo();
        }
        return results;
    }

    function batchForceStop(
        address[] calldata _battleids
    ) external onlyRole(MODERATOR_ROLE) {
        for (uint256 index = 0; index < _battleids.length; index++) {
            BattleV2(_battleids[index]).forceStop();
        }
    }
}
