// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    struct CardAction {
        uint256 tokenid;
        uint256 targetid;
        uint256 actionid;
    }

    struct TurnAction {
        address owner;
        address winner;
        CardAction[] actions;
    }
}
