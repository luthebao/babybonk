// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Reentrancy.sol";

contract Storage is AccessControl, Reentrancy {
    bytes32 public constant MODERATOR = keccak256("MODERATOR_ROLE");

    // Class ID:
    // 1 = warrior
    // 2 = magician
    // 3 = blitz
    // 4 = tank

    // Rare ID:
    // 1 = common
    // 2 = rare
    // 3 = ultra rare
    // 4 = legendary

    struct CardInfo {
        uint256 tokenid;
        uint256 imgid;
        uint256 classid;
        uint256 rare;
    }

    // Permanent Item Kind:
    // 1 = BONK BAT
    // 2 = SUPER BONK BAT
    // 3 = WOODEN SHIELD
    // 4 = CAPTAINS SHIELD
    // 5 = WINGS OF TRAVEL
    // 6 = WINGS OF LIGHT
    // 7 = MAGIC WAND
    // 8 = SCEPTER OF GODS

    struct PermanentItem {
        uint256 tokenid;
        uint256 kind;
    }

    struct BaseStat {
        int hp;
        int mana;
        int strength;
        int speed;
        int avoid;
        int armor;
    }

    mapping(uint256 => CardInfo) public CardInfos;
    mapping(uint256 => PermanentItem) public PermanentItems;

    mapping(uint256 => mapping(uint256 => BaseStat)) public basestats;
    mapping(uint256 => BaseStat) public itemstats;
    mapping(uint256 => BaseStat) public consumstats;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        _grantRole(MODERATOR, address(msg.sender));
        BaseStat memory _war = BaseStat(
            200, // hp
            100, // mp
            20, // damage
            20, // speed
            20, // avoid
            10 // armor
        );
        // warrior
        basestats[1][1] = _war;

        basestats[1][2] = _war;
        basestats[1][2].hp = _war.hp + 100;
        basestats[1][2].strength = _war.strength + 10;

        basestats[1][3] = _war;
        basestats[1][3].hp = _war.hp + 100;
        basestats[1][3].mana = _war.mana + 100;
        basestats[1][3].strength = _war.strength + 10;
        basestats[1][3].speed = _war.speed + 10;

        basestats[1][4] = _war;
        basestats[1][4].hp = _war.hp + 200;
        basestats[1][4].mana = _war.mana + 200;
        basestats[1][4].strength = _war.strength + 20;
        basestats[1][4].speed = _war.speed + 20;
        basestats[1][4].avoid = _war.speed + 20;
        basestats[1][4].armor = _war.speed + 20;

        BaseStat memory _magic = BaseStat(
            100, // hp
            300, // mp
            20, // damage
            20, // speed
            20, // avoid
            5 // armor
        );
        basestats[2][1] = _magic;

        basestats[2][2] = _magic;
        basestats[2][2].hp = _magic.hp + 100;
        basestats[2][2].strength = _magic.strength + 10;

        basestats[2][3] = _magic;
        basestats[2][3].hp = _magic.hp + 100;
        basestats[2][3].mana = _magic.mana + 100;
        basestats[2][3].strength = _magic.strength + 10;
        basestats[2][3].speed = _magic.speed + 10;

        basestats[2][4] = _magic;
        basestats[2][4].hp = _magic.hp + 200;
        basestats[2][4].mana = _magic.mana + 200;
        basestats[2][4].strength = _magic.strength + 20;
        basestats[2][4].speed = _magic.speed + 20;
        basestats[2][4].avoid = _magic.speed + 20;
        basestats[2][4].armor = _magic.speed + 20;

        BaseStat memory _blitz = BaseStat(
            100, // hp
            100, // mp
            20, // damage
            30, // speed
            30, // avoid
            5 // armor
        );
        basestats[3][1] = _blitz;

        basestats[3][2] = _blitz;
        basestats[3][2].hp = _blitz.hp + 100;
        basestats[3][2].strength = _blitz.strength + 10;

        basestats[3][3] = _blitz;
        basestats[3][3].hp = _blitz.hp + 100;
        basestats[3][3].mana = _blitz.mana + 100;
        basestats[3][3].strength = _blitz.strength + 10;
        basestats[3][3].speed = _blitz.speed + 10;

        basestats[3][4] = _blitz;
        basestats[3][4].hp = _blitz.hp + 200;
        basestats[3][4].mana = _blitz.mana + 200;
        basestats[3][4].strength = _blitz.strength + 20;
        basestats[3][4].speed = _blitz.speed + 20;
        basestats[3][4].avoid = _blitz.speed + 20;
        basestats[3][4].armor = _blitz.speed + 20;

        BaseStat memory _tank = BaseStat(
            300, // hp
            100, // mp
            20, // damage
            10, // speed
            10, // avoid
            15 // armor
        );
        basestats[4][1] = _tank;

        basestats[4][2] = _tank;
        basestats[4][2].hp = _tank.hp + 100;
        basestats[4][2].strength = _tank.strength + 10;

        basestats[4][3] = _tank;
        basestats[4][3].hp = _tank.hp + 100;
        basestats[4][3].mana = _tank.mana + 100;
        basestats[4][3].strength = _tank.strength + 10;
        basestats[4][3].speed = _tank.speed + 10;

        basestats[4][4] = _tank;
        basestats[4][4].hp = _tank.hp + 200;
        basestats[4][4].mana = _tank.mana + 200;
        basestats[4][4].strength = _tank.strength + 20;
        basestats[4][4].speed = _tank.speed + 20;
        basestats[4][4].avoid = _tank.speed + 20;
        basestats[4][4].armor = _tank.speed + 20;

        consumstats[1] = BaseStat(
            20, // hp
            0, // mp
            0, // damage
            0, // speed
            0, // avoid
            0 // armor
        );

        consumstats[2] = BaseStat(
            0, // hp
            20, // mp
            0, // damage
            0, // speed
            0, // avoid
            0 // armor
        );

        consumstats[3] = BaseStat(
            0, // hp
            0, // mp
            5, // damage
            0, // speed
            0, // avoid
            0 // armor
        );

        consumstats[4] = BaseStat(
            0, // hp
            0, // mp
            5, // damage
            0, // speed
            0, // avoid
            0 // armor
        );
    }

    function getBaseStat(
        uint256 _classid,
        uint256 _rare
    ) public view returns (BaseStat memory) {
        return basestats[_classid][_rare];
    }

    function updateBaseStat(
        uint256 classid,
        int hp,
        int mana,
        int strength,
        int speed,
        int avoid,
        int armor
    ) external onlyRole(MODERATOR) {
        BaseStat memory _base = BaseStat(
            hp,
            mana,
            strength,
            speed,
            avoid,
            armor
        );
        basestats[classid][1] = _base;

        basestats[classid][2] = _base;
        basestats[classid][2].hp = _base.hp + 100;
        basestats[classid][2].strength = _base.strength + 10;

        basestats[classid][3] = _base;
        basestats[classid][3].hp = _base.hp + 100;
        basestats[classid][3].mana = _base.mana + 100;
        basestats[classid][3].strength = _base.strength + 10;
        basestats[classid][3].speed = _base.speed + 10;

        basestats[classid][4] = _base;
        basestats[classid][4].hp = _base.hp + 200;
        basestats[classid][4].mana = _base.mana + 200;
        basestats[classid][4].strength = _base.strength + 20;
        basestats[classid][4].speed = _base.speed + 20;
        basestats[classid][4].avoid = _base.speed + 20;
        basestats[classid][4].armor = _base.speed + 20;
    }

    function addCardInfo(
        uint256 _tokenid,
        uint256 _imgid,
        uint256 _classid,
        uint256 _rare
    ) external onlyRole(MODERATOR) {
        CardInfos[_tokenid] = CardInfo(_tokenid, _imgid, _classid, _rare);
    }

    function addPermanentInfo(
        uint256 _tokenid,
        uint256 _kind
    ) external onlyRole(MODERATOR) {
        PermanentItems[_tokenid] = PermanentItem(_tokenid, _kind);
    }
}
