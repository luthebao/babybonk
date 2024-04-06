// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";
import "./BattleLib.sol";

contract Battle is AccessControl, Reentrancy {
    bytes32 public constant FIGHTER_ROLE = keccak256("FIGHTER_ROLE");
    uint256 private _nextBattleId;

    IERC20 public token_bet;
    IERC721 public card_nft;
    BattleLib.BattleInfo private battleinfo;
    uint256 private roundtime = 2 minutes;
    uint256 public starttime;

    uint256 public curruntTurnId;
    uint256 public maxTimeCurrentTurn;

    // mapping from turnid => bytes
    mapping(uint256 => bytes) public turnSignData;
    mapping(uint256 => mapping(address => BattleLib.TurnAction))
        public turnData;
    // mapping from turn id => fighters => signed?
    mapping(uint256 => mapping(address => bool)) public turnSigned;
    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(address => uint256[]) public nfts;

    event BattleStart(
        address battleid,
        address owner,
        address fighter,
        uint256 start
    );

    event BattleStop(
        address battleid,
        address owner,
        address fighter,
        address winner
    );

    constructor(address _bet_token, address _card_nft, address _gm) {
        _grantRole(DEFAULT_ADMIN_ROLE, _gm);
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        token_bet = IERC20(_bet_token);
        card_nft = IERC721(_card_nft);
    }

    function initBattleInfo(
        BattleLib.BattleInfo calldata _info
    ) external onlyRole(DEFAULT_ADMIN_ROLE) lock {
        require(battleinfo.owner == address(0), "already init");
        battleinfo = _info;
        _grantRole(FIGHTER_ROLE, battleinfo.owner);
    }

    function getBattleInfo() public view returns (BattleLib.BattleInfo memory) {
        return battleinfo;
    }

    function getNFTs(
        address _account
    ) external view returns (uint256[] memory) {
        return nfts[_account];
    }

    function encodeTInfo(
        BattleLib.TurnAction[] calldata _actions
    ) external pure returns (bytes memory) {
        return abi.encode(_actions);
    }

    function decodeTInfo(
        bytes calldata _actionsData
    ) public pure returns (BattleLib.TurnAction[] memory actions) {
        actions = abi.decode(_actionsData, (BattleLib.TurnAction[]));
    }

    function signTurn(
        bytes calldata _turninfo
    ) external lock onlyRole(FIGHTER_ROLE) {
        uint256 myturnId = curruntTurnId;
        bytes memory turndata = turnSignData[myturnId];

        if (keccak256(turndata) == bytes32(0)) {
            turnSignData[myturnId] = _turninfo;
        } else {
            require(keccak256(turnSignData[myturnId]) == keccak256(_turninfo));
        }
        turnSigned[myturnId][address(msg.sender)] = true;

        if (
            turnSigned[myturnId][battleinfo.owner] == true &&
            turnSigned[myturnId][battleinfo.fighter] == true
        ) {
            BattleLib.TurnAction[] memory _actions = abi.decode(
                _turninfo,
                (BattleLib.TurnAction[])
            );
            for (uint256 index = 0; index < _actions.length; index++) {
                turnData[myturnId][_actions[index].owner] = _actions[index];
            }
            if (
                turnData[myturnId][battleinfo.owner].winner ==
                turnData[myturnId][battleinfo.fighter].winner &&
                turnData[myturnId][battleinfo.owner].winner != address(0)
            ) {
                battleinfo.status = BattleLib.BattleStatus.ENDED;
                battleinfo.winner = turnData[myturnId][battleinfo.owner].winner;
            }
            curruntTurnId = curruntTurnId + 1;
        }
        maxTimeCurrentTurn = block.timestamp + 10 minutes;
    }

    function joinBattle(uint256[] calldata _tokenids) external lock {
        if (address(msg.sender) == address(battleinfo.owner)) {
            require(battleinfo.fighter != address(0), "no fighter in battle");
            battleinfo.status = BattleLib.BattleStatus.STARTED;
            starttime = block.timestamp;
            maxTimeCurrentTurn = block.timestamp + 10 minutes;
            emit BattleStart(
                battleinfo.battleid,
                battleinfo.owner,
                battleinfo.fighter,
                starttime
            );
        } else {
            require(!hasRole(FIGHTER_ROLE, msg.sender));
            require(battleinfo.status == BattleLib.BattleStatus.PENDING);
            require(battleinfo.fighter == address(0));

            bool check_transfer = token_bet.transferFrom(
                msg.sender,
                address(this),
                battleinfo.betamount
            );
            require(check_transfer);
            _grantRole(FIGHTER_ROLE, msg.sender);
            battleinfo.fighter = address(msg.sender);
        }
        nfts[msg.sender] = _tokenids;
        for (uint256 index = 0; index < _tokenids.length; index++) {
            card_nft.transferFrom(
                address(msg.sender),
                address(this),
                _tokenids[index]
            );
        }
    }

    function exitBattle() external lock onlyRole(FIGHTER_ROLE) {
        require(
            battleinfo.status != BattleLib.BattleStatus.ENDED,
            "battle ended"
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
        emit BattleStop(
            battleinfo.battleid,
            battleinfo.owner,
            battleinfo.fighter,
            battleinfo.winner
        );
    }

    function forceStop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp > maxTimeCurrentTurn);
        battleinfo.status = BattleLib.BattleStatus.ENDED;
        battleinfo.winner = address(0);
    }

    function claim() external lock onlyRole(FIGHTER_ROLE) {
        require(battleinfo.status == BattleLib.BattleStatus.ENDED);
        if (battleinfo.winner == address(0)) {
            token_bet.transfer(address(msg.sender), battleinfo.betamount);
        } else {
            if (address(msg.sender) == battleinfo.winner) {
                token_bet.transfer(
                    address(msg.sender),
                    token_bet.balanceOf(address(this))
                );
            }
        }
        for (uint256 index = 0; index < nfts[msg.sender].length; index++) {
            card_nft.safeTransferFrom(
                address(this),
                address(msg.sender),
                nfts[msg.sender][index]
            );
        }
        revokeRole(FIGHTER_ROLE, msg.sender);
    }
}
