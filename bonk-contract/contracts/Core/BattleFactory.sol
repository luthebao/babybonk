// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Battle.sol";

contract BattleFactory is Reentrancy {
    address[] private battleList;
    mapping(address => address[]) private battleOfOwner;

    IERC20 public token_bet;
    bool public paused;

    event BattleCreate(address battleid, address owner);

    constructor(address bet_token) {
        token_bet = IERC20(address(bet_token));
    }

    function createBattle(uint256 _mode, uint256 _bet_amount) external lock {
        require(!paused, "battle system is on maintenance");
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
        Battle mybattle = new Battle(address(token_bet));
        require(
            (
                token_bet.transferFrom(
                    msg.sender,
                    address(mybattle),
                    _bet_amount
                )
            ),
            "transfer token to battle failed"
        );
        BattleLib.BattleInfo memory createdBattle = BattleLib.BattleInfo(
            address(mybattle),
            address(msg.sender),
            address(0),
            address(0),
            _bet_amount,
            __mode,
            BattleLib.BattleStatus.PENDING
        );
        mybattle.initBattleInfo(createdBattle);
        battleOfOwner[msg.sender].push(address(mybattle));
        battleList.push(address(mybattle));
        emit BattleCreate(address(mybattle), address(msg.sender));
    }

    function getBattleInfo(
        address _battleid
    ) public view returns (BattleLib.BattleInfo memory) {
        return Battle(_battleid).getBattleInfo();
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
}
