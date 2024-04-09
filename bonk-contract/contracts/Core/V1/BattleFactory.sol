// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Battle.sol";

contract BattleFactory is AccessControl, Reentrancy {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    address[] private battleList;
    mapping(address => address[]) private battleOfOwner;
    IERC20 public token_bet;
    IERC721 public card_nft;
    address public storageNFT;
    bool public paused;
    address public gameMaster;
    event BattleCreate(address battleid, address owner);
    mapping(uint256 => BattleLib.SkillEffect) public skills;
    constructor(address _bet_token, address _card_nft, address _storageNFT) {
        token_bet = IERC20(address(_bet_token));
        card_nft = IERC721(address(_card_nft));
        gameMaster = address(msg.sender);
        storageNFT = address(_storageNFT);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
    }

    function updateSkill(
        BattleLib.SkillEffect calldata _data
    ) external onlyRole(MODERATOR_ROLE) {
        skills[_data.skillid] = _data;
    }

    function createBattle(uint256 _mode, uint256 _bet_amount) external lock {
        require(!paused, "maintenance");
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
        Battle mybattle = new Battle(
            address(token_bet),
            address(card_nft),
            address(storageNFT),
            gameMaster
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
            results[index] = Battle(_battleid).getBattleInfo();
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
            results[index] = Battle(_battleid).getBattleInfo();
        }
        return results;
    }

    function batchForceStop(
        address[] calldata _battleids
    ) external lock onlyRole(MODERATOR_ROLE) {
        for (uint256 index = 0; index < _battleids.length; index++) {
            Battle(_battleids[index]).forceStop();
        }
    }
}
