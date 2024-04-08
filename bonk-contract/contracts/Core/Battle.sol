// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";
import "./BattleLib.sol";

interface IStorage {
    struct CardInfo {
        uint256 tokenid;
        uint256 imgid;
        uint256 classid;
        uint256 rare;
    }
    struct BaseStat {
        int hp;
        int mana;
        int strength;
        int speed;
        int avoid;
        int armor;
    }

    function CardInfos(uint256) external view returns (CardInfo memory);

    function getBaseStat(
        uint256,
        uint256
    ) external view returns (BaseStat memory);
}

interface ISkillManager {
    function skills(
        uint256
    ) external view returns (BattleLib.SkillEffect memory);
}

contract Battle is AccessControl, Reentrancy {
    bytes32 public constant FIGHTER_ROLE = keccak256("FIGHTER_ROLE");
    uint256 private _nextBattleId;

    IERC20 public token_bet;
    IERC721 public card_nft;
    IStorage public storageNFT;
    ISkillManager public skillmanager;
    BattleLib.BattleInfo private battleinfo;
    uint256 private roundtime = 2 minutes;
    uint256 public starttime;

    uint256 public curruntTurnId;
    uint256 public maxTimeCurrentTurn;

    // mapping from turnid => bytes
    mapping(uint256 => BattleLib.CardAction[]) public turnData;
    mapping(uint256 => mapping(address => BattleLib.CardAction[]))
        public turnDataUser;
    mapping(uint256 => mapping(uint256 => BattleLib.CardAction))
        public turnDetailByTokenid;
    // mapping from turn id => fighters => signed?
    mapping(uint256 => mapping(address => bool)) public turnSigned;
    mapping(uint256 => BattleLib.NFTState) public nftstates;
    // list tokenid of
    mapping(address => uint256[]) public nfts;
    uint256 private nonce;

    struct TurnStat {
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
        int reflect;
        int blockdmg;
    }

    mapping(uint256 => TurnStat[]) private turnstats;
    mapping(uint256 => mapping(uint256 => TurnStat)) private turnstatByTokenid;

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

    constructor(
        address _bet_token,
        address _card_nft,
        address _storageNFT,
        address _gm
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _gm);
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        token_bet = IERC20(_bet_token);
        card_nft = IERC721(_card_nft);
        storageNFT = IStorage(_storageNFT);
        skillmanager = ISkillManager(address(msg.sender));
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

    function getNFTStates(
        address _account
    ) external view returns (BattleLib.NFTState[] memory) {
        BattleLib.NFTState[] memory results = new BattleLib.NFTState[](
            nfts[_account].length
        );
        for (uint256 index = 0; index < nfts[_account].length; index++) {
            results[index] = nftstates[nfts[_account][index]];
        }
        return results;
    }

    function getAllTurn()
        external
        view
        returns (BattleLib.TurnAction[] memory)
    {
        BattleLib.TurnAction[] memory results = new BattleLib.TurnAction[](
            curruntTurnId
        );
        for (uint256 index = 0; index < curruntTurnId; index++) {
            results[index] = BattleLib.TurnAction(index, turnData[index]);
        }
        return results;
    }

    function setTurn(
        BattleLib.CardAction[] calldata _actions
    ) external lock onlyRole(FIGHTER_ROLE) {
        uint256 myturnId = curruntTurnId;
        require(
            _actions.length <=
                (battleinfo.mode == BattleLib.BattleMode.FIVE ? 5 : 3)
        );
        require(!turnSigned[myturnId][address(msg.sender)]);
        turnDataUser[myturnId][address(msg.sender)] = _actions;
        turnSigned[myturnId][address(msg.sender)] = true;
        for (uint256 index = 0; index < _actions.length; index++) {
            turnDetailByTokenid[myturnId][_actions[index].tokenid] = _actions[
                index
            ];
        }
        if (
            turnSigned[myturnId][battleinfo.owner] == true &&
            turnSigned[myturnId][battleinfo.fighter] == true
        ) {
            BattleLib.CardAction[] memory _action_owner = turnDataUser[
                myturnId
            ][battleinfo.owner];
            BattleLib.CardAction[] memory _action_fighter = turnDataUser[
                myturnId
            ][battleinfo.owner];
            BattleLib.CardAction[] memory _temp = new BattleLib.CardAction[](
                _action_owner.length + _action_fighter.length
            );
            uint256 rindex = 0;
            for (uint256 index = 0; index < _action_owner.length; index++) {
                _temp[rindex] = _action_owner[index];
                rindex++;
            }
            for (uint256 index = 0; index < _action_fighter.length; index++) {
                _temp[rindex] = _action_fighter[index];
                rindex++;
            }
            turnData[myturnId] = _temp;
            sync();
            curruntTurnId = curruntTurnId + 1;
            maxTimeCurrentTurn = block.timestamp + 10 minutes;
        }
    }

    function addTurnStat() internal {
        // commit first turn stat for each card
        for (
            uint256 index = 0;
            index < nfts[battleinfo.owner].length;
            index++
        ) {
            uint256 _tokenid = nfts[battleinfo.owner][index];
            BattleLib.NFTState memory _tempstate = nftstates[_tokenid];
            turnstatByTokenid[curruntTurnId][_tokenid] = TurnStat(
                _tempstate.owner,
                _tempstate.tokenid,
                _tempstate.classid,
                _tempstate.rare,
                _tempstate.hp,
                _tempstate.mana,
                _tempstate.strength,
                _tempstate.speed,
                _tempstate.avoid,
                _tempstate.armor,
                0,
                0
            );
        }
        for (
            uint256 index = 0;
            index < nfts[battleinfo.fighter].length;
            index++
        ) {
            uint256 _tokenid = nfts[battleinfo.fighter][index];
            BattleLib.NFTState memory _tempstate = nftstates[_tokenid];
            turnstatByTokenid[curruntTurnId][_tokenid] = TurnStat(
                _tempstate.owner,
                _tempstate.tokenid,
                _tempstate.classid,
                _tempstate.rare,
                _tempstate.hp,
                _tempstate.mana,
                _tempstate.strength,
                _tempstate.speed,
                _tempstate.avoid,
                _tempstate.armor,
                0,
                0
            );
        }

        // inject active skill (speed/block)
        for (
            uint256 index = 0;
            index < turnData[curruntTurnId].length;
            index++
        ) {
            BattleLib.CardAction memory _tempAction = turnData[curruntTurnId][
                index
            ];
            address _ownerOfAction = _tempAction.owner;
            if (_tempAction.skillid == 9 || _tempAction.skillid == 10) {
                turnstatByTokenid[curruntTurnId][_tempAction.tokenid]
                    .speed = type(int).max;
            } else if (_tempAction.skillid == 3) {
                if (isTheSameTeam(_tempAction.targetid, _ownerOfAction)) {
                    turnstatByTokenid[curruntTurnId][_tempAction.targetid]
                        .blockdmg = 30;
                } else {
                    uint256 _randomTokenId = randomInArray(
                        nfts[_ownerOfAction]
                    );
                    turnstatByTokenid[curruntTurnId][_randomTokenId]
                        .blockdmg = 30;
                }
            } else if (_tempAction.skillid == 12) {
                turnstatByTokenid[curruntTurnId][_tempAction.tokenid]
                    .armor += 5;
                turnstatByTokenid[curruntTurnId][_tempAction.tokenid]
                    .reflect = 50;
            }
        }

        for (
            uint256 index = 0;
            index < nfts[battleinfo.owner].length;
            index++
        ) {
            uint256 _tokenid = nfts[battleinfo.owner][index];
            turnstats[curruntTurnId].push(
                turnstatByTokenid[curruntTurnId][_tokenid]
            );
        }
        for (
            uint256 index = 0;
            index < nfts[battleinfo.fighter].length;
            index++
        ) {
            uint256 _tokenid = nfts[battleinfo.fighter][index];
            turnstats[curruntTurnId].push(
                turnstatByTokenid[curruntTurnId][_tokenid]
            );
        }
        bubbleSort(turnstats[curruntTurnId]);
    }

    function sync() internal {
        addTurnStat();
        for (
            uint256 index = 0;
            index < turnstats[curruntTurnId].length;
            index++
        ) {
            int _cost_mana;
            TurnStat memory _turnstat = turnstats[curruntTurnId][index];
            BattleLib.CardAction memory _action = turnDetailByTokenid[
                curruntTurnId
            ][_turnstat.tokenid];
            TurnStat memory _turnstatTarget = turnstatByTokenid[curruntTurnId][
                _action.targetid
            ];
            BattleLib.NFTState memory _currentState = nftstates[
                _turnstat.tokenid
            ];
            BattleLib.NFTState memory _targetState = nftstates[
                _action.targetid
            ];
            address _target_add = _turnstat.owner == battleinfo.owner
                ? battleinfo.fighter
                : battleinfo.owner;
            if (_currentState.hp == 0) {
                continue;
            }
            if (_action.skillid == 1) {
                // bonk
                _cost_mana = 5;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _takedmg = uint256(_currentState.strength) >=
                        uint256(_targetState.armor)
                        ? 10 +
                            uint256(_currentState.strength) -
                            uint256(_targetState.armor)
                        : 10;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;

                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }

                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 2) {
                // super bonk
                _cost_mana = 20;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _takedmg = uint256(_currentState.strength) >=
                        uint256(_targetState.armor)
                        ? 20 +
                            uint256(_currentState.strength) -
                            uint256(_targetState.armor)
                        : 20;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }
                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 3) {
                // block
                _cost_mana = 15;
            } else if (_action.skillid == 4) {
                // nothing
                _cost_mana = 0;
                IStorage.BaseStat memory _basestat = storageNFT.getBaseStat(
                    _currentState.classid,
                    _currentState.rare
                );
                if (_currentState.hp + 5 >= _basestat.hp) {
                    nftstates[_turnstat.tokenid].hp = _basestat.hp;
                } else {
                    nftstates[_turnstat.tokenid].hp += 5;
                }
                if (_currentState.mana + 5 >= _basestat.mana) {
                    nftstates[_turnstat.tokenid].mana = _basestat.mana;
                } else {
                    nftstates[_turnstat.tokenid].mana += 5;
                }
            } else if (_action.skillid == 5) {
                // GLADIATOR BONK
                _cost_mana = 25;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _muldmg3 = random(1, 100) < 25 ? 2 : 3;
                    uint256 _takedmg = _currentState.strength >=
                        _targetState.armor
                        ? 25 +
                            uint256(_currentState.strength) -
                            uint256(_targetState.armor)
                        : 25;
                    _takedmg = (_takedmg * 3) / _muldmg3;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }
                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 6) {
                // BERSERKER
                _cost_mana = 30;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _muldmgInstance = random(1, 100) < (12 + _currentState.rare * 3) ? 1 : 0;
                    uint256 _takedmg = uint256(_targetState.hp) *
                        _muldmgInstance;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }
                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 7) {
                // BONK OF THE VOID
                _cost_mana = 25;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _muldmg3 = random(1, 100) < 12 ? 2 : 3;
                    uint256 _takedmg = uint256(_currentState.strength) >=
                        uint256(_targetState.armor)
                        ? 25 +
                            uint256(_currentState.strength) -
                            uint256(_targetState.armor)
                        : 25;
                    _takedmg = (_takedmg * 3) / _muldmg3;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }
                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 8) {
                // LIFE OF THE ANCESTORS
                _cost_mana = 30;
                if (_currentState.mana >= _cost_mana) {
                    IStorage.BaseStat memory _basestat = storageNFT.getBaseStat(
                        _targetState.classid,
                        _targetState.rare
                    );
                    int _value_health = 20;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = randomInArray(nfts[_action.owner]);
                    } else {
                        _targetid = _action.targetid;
                    }
                    if (_targetState.hp + _value_health >= _basestat.hp) {
                        nftstates[_targetid].hp = _basestat.hp;
                    } else {
                        nftstates[_targetid].hp += _value_health;
                    }
                }
            } else if (_action.skillid == 9) {
                // LIGHTNING DASH
                _cost_mana = 25;
                if (_currentState.mana >= _cost_mana) {
                    uint256 _takedmg = uint256(_currentState.strength) >=
                        uint256(_targetState.armor)
                        ? 15 +
                            uint256(_currentState.strength) -
                            uint256(_targetState.armor)
                        : 15;
                    uint256 _flectdmg = (_takedmg *
                        uint256(_turnstatTarget.reflect)) / 100;
                    _takedmg =
                        (_takedmg * (100 - uint256(_turnstatTarget.blockdmg))) /
                        100;
                    uint256 _targetid = _action.targetid;
                    if (isTheSameTeam(_targetid, _target_add)) {
                        _targetid = _action.targetid;
                    } else {
                        _targetid = randomInArray(nfts[_target_add]);
                    }
                    if (_targetState.hp <= int(_takedmg)) {
                        nftstates[_targetid].hp = 0;
                    } else {
                        nftstates[_targetid].hp -= int(_takedmg);
                    }
                    if (_flectdmg > 0) {
                        if (_currentState.hp <= int(_flectdmg)) {
                            nftstates[_turnstat.tokenid].hp = 0;
                        } else {
                            nftstates[_turnstat.tokenid].hp -= int(_flectdmg);
                        }
                    }
                }
            } else if (_action.skillid == 10) {
                // LIGHTNING BONK
                _cost_mana = 30;
                if (_currentState.mana >= _cost_mana) {
                    for (uint256 i2 = 0; i2 < nfts[_target_add].length; i2++) {
                        uint256 _temp_tg_tokenid = nfts[_target_add][i2];
                        TurnStat memory _temp_tgstat = turnstatByTokenid[
                            curruntTurnId
                        ][_temp_tg_tokenid];
                        uint256 _takedmg = uint256(_currentState.strength) >=
                            uint256(_temp_tgstat.armor)
                            ? 20 +
                                uint256(_currentState.strength) -
                                uint256(_temp_tgstat.armor)
                            : 20;
                        _takedmg = _takedmg / 2;
                        uint256 _flectdmg = (_takedmg *
                            uint256(_turnstatTarget.reflect)) / 100;
                        _takedmg =
                            (_takedmg *
                                (100 - uint256(_turnstatTarget.blockdmg))) /
                            100;
                        if (_temp_tgstat.hp <= int(_takedmg)) {
                            nftstates[_temp_tg_tokenid].hp = 0;
                        } else {
                            nftstates[_temp_tg_tokenid].hp -= int(_takedmg);
                        }
                        if (_flectdmg > 0) {
                            if (_currentState.hp <= int(_flectdmg)) {
                                nftstates[_turnstat.tokenid].hp = 0;
                            } else {
                                nftstates[_turnstat.tokenid].hp -= int(
                                    _flectdmg
                                );
                            }
                        }
                    }
                }
            } else if (_action.skillid == 12) {
                // IRON FORTRESS
                _cost_mana = 30;
            }
            if (_currentState.mana <= _cost_mana) {
                nftstates[_turnstat.tokenid].mana = 0;
            } else {
                if (_cost_mana > 0) {
                    nftstates[_turnstat.tokenid].mana -= _cost_mana;
                }
            }
        }
        checkDone();
    }

    function isTheSameTeam(
        uint256 _tokenid,
        address _check
    ) internal view returns (bool) {
        for (uint256 index = 0; index < nfts[_check].length; index++) {
            if (_tokenid == nfts[_check][index]) {
                return true;
            }
        }
        return false;
    }

    function randomInArray(
        uint256[] memory _myArray
    ) internal returns (uint256) {
        if (_myArray.length == 0) {
            return 1;
        }
        uint a = _myArray.length;
        uint b = _myArray.length;
        for (uint i = 0; i < b; i++) {
            nonce++;
            uint256 randNumber = uint256(
                uint(
                    keccak256(
                        abi.encodePacked(block.timestamp, msg.sender, nonce)
                    )
                ) % a
            ) + 1;
            uint256 interim = _myArray[randNumber - 1];
            _myArray[randNumber - 1] = _myArray[a - 1];
            _myArray[a - 1] = interim;
            a = a - 1;
        }
        uint256[] memory result;
        result = _myArray;
        return result[0];
    }

    function checkDone() internal {
        uint256 _owner_num;
        uint256 _fight_num;
        for (
            uint256 index = 0;
            index < nfts[battleinfo.owner].length;
            index++
        ) {
            uint256 _tokenid = nfts[battleinfo.owner][index];
            BattleLib.NFTState memory _tempstate = nftstates[_tokenid];
            if (_tempstate.hp == 0) {
                _owner_num += 1;
            }
        }
        if (nfts[battleinfo.owner].length == _owner_num) {
            battleinfo.status = BattleLib.BattleStatus.ENDED;
            battleinfo.winner = battleinfo.fighter;
        } else {
            for (
                uint256 index = 0;
                index < nfts[battleinfo.fighter].length;
                index++
            ) {
                uint256 _tokenid = nfts[battleinfo.fighter][index];
                BattleLib.NFTState memory _tempstate = nftstates[_tokenid];
                if (_tempstate.hp == 0) {
                    _fight_num += 1;
                }
            }
            if (nfts[battleinfo.fighter].length == _fight_num) {
                battleinfo.status = BattleLib.BattleStatus.ENDED;
                battleinfo.winner = battleinfo.owner;
            }
        }
    }

    function joinBattle(uint256[] calldata _tokenids) external lock {
        require(
            _tokenids.length ==
                (battleinfo.mode == BattleLib.BattleMode.FIVE ? 5 : 3)
        );
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
            IStorage.CardInfo memory info = storageNFT.CardInfos(
                _tokenids[index]
            );
            IStorage.BaseStat memory stat = storageNFT.getBaseStat(
                info.classid,
                info.rare
            );
            nftstates[_tokenids[index]] = BattleLib.NFTState(
                address(msg.sender),
                _tokenids[index],
                info.classid,
                info.rare,
                stat.hp,
                stat.mana,
                stat.strength,
                stat.speed,
                stat.avoid,
                stat.armor
            );
            card_nft.transferFrom(
                address(msg.sender),
                address(this),
                _tokenids[index]
            );
        }
    }

    function bubbleSort(TurnStat[] storage arr) internal {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j].speed < arr[j + 1].speed) {
                    TurnStat memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }
    function random(uint256 _min, uint256 _max) internal returns (uint256) {
        nonce++;
        return
            uint256(
                uint(
                    keccak256(
                        abi.encodePacked(block.timestamp, msg.sender, nonce)
                    )
                ) % (_max - _min + 1)
            ) + _min;
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
        _revokeRole(FIGHTER_ROLE, msg.sender);
    }
}
