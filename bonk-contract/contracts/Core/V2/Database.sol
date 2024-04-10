// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Reentrancy.sol";

contract Database is AccessControl, Reentrancy {
    struct NFTState {
        address owner;
        uint256 tokenid;
        uint256 classid;
        uint256 rare;
        uint256 hp;
        uint256 mana;
        uint256 strength;
        uint256 speed;
        uint256 avoid;
        uint256 armor;
    }
    /// @notice mapping of battleid => tokenid => state
    mapping(address => mapping(uint256 => NFTState)) private nftstate;

    struct Attack {
        address owner;
        uint256 tokenid;
        uint256 targetid;
        uint256 skillid;
    }

    struct RoundLog {
        uint256 turn;
        Attack[] logs;
    }

    /// @notice mapping of battleid => turn => state
    mapping(address => mapping(uint256 => Attack[])) private roundlog;

    struct Battle {
        address battleid;
        address owner;
        uint256[] nftowner;
        address fighter;
        uint256[] nftfighter;
        uint256 turn;
        address winner;
        uint256 mode;
    }

    mapping(address => mapping(address => bytes)) public signatures;

    mapping(address => uint256) public lasttimeaction;

    mapping(address => Battle) private battles;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
    }

    function updateSignature(
        address _battleid,
        address _account,
        bytes memory _s
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signatures[_battleid][_account].length == 0);
        signatures[_battleid][_account] = _s;
    }

    function addBattle(
        Battle calldata _data
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            battles[_data.battleid].owner == address(0) &&
            _data.battleid != address(0)
        ) {
            battles[_data.battleid] = _data;
            lasttimeaction[_data.battleid] = block.timestamp;
        }
    }

    function increaseTurn(
        address _battleid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (battles[_battleid].owner != address(0)) {
            Battle storage battle = battles[_battleid];
            battle.turn += 1;
            lasttimeaction[_battleid] = block.timestamp;
        }
    }

    function updateWinner(
        address _battleid,
        address _winner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (battles[_battleid].owner != address(0)) {
            Battle storage battle = battles[_battleid];
            battle.winner = _winner;
        }
    }

    function getBattle(
        address _battleid
    ) external view returns (Battle memory) {
        return battles[_battleid];
    }

    function updateRoundLog(
        address _battleid,
        Attack[] calldata _attacks
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Battle memory battle = battles[_battleid];
        for (uint256 index = 0; index < _attacks.length; index++) {
            roundlog[_battleid][battle.turn].push(_attacks[index]);
        }
    }

    function getCurrentAttackLog(
        address _battleid
    ) external view returns (Attack[] memory) {
        Battle memory battle = battles[_battleid];
        return roundlog[_battleid][battle.turn];
    }

    function getRoundLog(
        address _battleid
    ) external view returns (RoundLog[] memory) {
        Battle memory battle = battles[_battleid];
        RoundLog[] memory results = new RoundLog[](battle.turn);
        for (uint256 index = 0; index < battle.turn; index++) {
            results[index] = RoundLog(index, roundlog[_battleid][index]);
        }
        return results;
    }

    function updateState(
        address _battleid,
        NFTState[] calldata _states
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < _states.length; index++) {
            NFTState memory state = _states[index];
            nftstate[_battleid][state.tokenid] = state;
        }
    }

    function getState(
        address _battleid
    ) external view returns (NFTState[] memory) {
        Battle memory battle = battles[_battleid];
        NFTState[] memory states = new NFTState[](
            battle.nftowner.length + battle.nftfighter.length
        );
        uint256 rindex;
        for (uint256 index = 0; index < battle.nftowner.length; index++) {
            states[rindex] = nftstate[_battleid][battle.nftowner[index]];
            rindex++;
        }
        for (uint256 index = 0; index < battle.nftfighter.length; index++) {
            states[rindex] = nftstate[_battleid][battle.nftfighter[index]];
            rindex++;
        }
        return states;
    }
}
