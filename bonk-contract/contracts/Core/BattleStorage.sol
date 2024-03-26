// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";

contract BattleStorage is AccessControl, Reentrancy {
    bytes32 public constant MODERATOR = keccak256("MODERATOR_ROLE");
    uint256 private _nextBattleId;

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
        address owner;
        address fighter;
        BattleMode mode;
        address winner;
        uint256 betamount;
        BattleStatus status; // 0 - waiting; 1 - started; 2 - ended
    }

    BattleInfo[] public battleList;
    mapping(uint256 => BattleInfo) private battles;
    mapping(address => BattleInfo[]) private battleOfOwner;

    address public token_bet;
    bool public paused;

    constructor(address bet_token) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        _grantRole(MODERATOR, address(msg.sender));
        token_bet = address(bet_token);
    }

    function createBattle(uint256 _mode, uint256 _bet_amount) external lock {
        require(!paused, "battle system is on maintenance");
        require(
            (
                IERC20(address(token_bet)).transferFrom(
                    msg.sender,
                    address(this),
                    _bet_amount
                )
            ),
            "Invalid token amount"
        );
        BattleMode __mode;
        if (_mode == 0) {
            __mode = BattleMode.THREE;
        } else {
            __mode = BattleMode.FIVE;
        }
        uint256 battleid = _nextBattleId++;
        BattleInfo memory createdBattle = BattleInfo(
            msg.sender,
            address(0),
            __mode,
            address(0),
            _bet_amount,
            BattleStatus.PENDING
        );

        battles[battleid] = createdBattle;
        battleOfOwner[msg.sender].push(createdBattle);
        battleList.push(createdBattle);
    }

    function getBattleByOwner(
        address _owner
    ) public view returns (BattleInfo[] memory) {
        return battleOfOwner[_owner];
    }
}
