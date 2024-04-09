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

    struct NFTState {
        address owner;
        uint256 tokenid;
        uint256 classid;
        uint256 rare;
        int hp;
        int mana;
        int strength;
        int speed;
        int avoid;
        int armor;
    }

    struct CardAction {
        address owner;
        uint256 tokenid;
        uint256 targetid;
        uint256 skillid;
    }

    struct TurnAction {
        uint256 turnid;
        CardAction[] actions;
    }

    enum EffectType {
        DAMAGE,
        DEFEND,
        HEAL,
        SELF_HEAL,
        INSTANT_KILL,
        AOE_DAMAGE,
        INSTANT_DAMAGE,
        PASSIVE_DEFEND,
        REFLECT,
        BUFF
    }

    struct SkillEffect {
        uint256 skillid;
        uint256 classid;
        uint256 manacost;
        EffectType effect;
        uint256 value;
    }
}
