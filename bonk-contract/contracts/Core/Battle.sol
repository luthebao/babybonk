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
    mapping(uint256 => bytes) public turnSignData;
    mapping(uint256 => BattleLib.CardAction[]) public turnData;
    mapping(uint256 => mapping(address => BattleLib.CardAction[]))
        public turnDataUser;
    // mapping from turn id => fighters => signed?
    mapping(uint256 => mapping(address => bool)) public turnSigned;
    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => BattleLib.NFTState) public nftstates;

    mapping(address => uint256[]) public nfts;

    BattleLib.NFTState[] private nftstat;

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
        require(!turnSigned[myturnId][address(msg.sender)]);
        turnDataUser[myturnId][address(msg.sender)] = _actions;
        turnSigned[myturnId][address(msg.sender)] = true;
        if (
            turnSigned[myturnId][battleinfo.owner] == true &&
            turnSigned[myturnId][battleinfo.fighter] == true
        ) {
            sync();
            BattleLib.CardAction[] memory _temp = new BattleLib.CardAction[](
                turnDataUser[myturnId][battleinfo.owner].length +
                    turnDataUser[myturnId][battleinfo.fighter].length
            );
            uint256 rindex;
            for (
                uint256 index = 0;
                index < turnDataUser[myturnId][battleinfo.owner].length;
                index++
            ) {
                _temp[rindex] = turnDataUser[myturnId][battleinfo.owner][index];
                rindex++;
            }
            for (
                uint256 index = 0;
                index < turnDataUser[myturnId][battleinfo.fighter].length;
                index++
            ) {
                _temp[rindex] = turnDataUser[myturnId][battleinfo.fighter][
                    index
                ];
                rindex++;
            }
            curruntTurnId = curruntTurnId + 1;
            maxTimeCurrentTurn = block.timestamp + 10 minutes;
        }
    }

    function sync() internal {
        for (uint256 index = 0; index < nftstat.length; index++) {
            BattleLib.NFTState memory _stat = nftstat[index];
            address _target_add = _stat.owner == battleinfo.owner
                ? battleinfo.owner
                : battleinfo.fighter;
            if (nftstates[_stat.tokenid].hp > 0) {
                for (
                    uint256 i1 = 0;
                    i1 < turnData[curruntTurnId].length;
                    i1++
                ) {
                    BattleLib.CardAction memory _tempAction = turnData[
                        curruntTurnId
                    ][i1];
                    if (_tempAction.tokenid == _stat.tokenid) {
                        BattleLib.SkillEffect memory _skill = skillmanager
                            .skills(_tempAction.skillid);
                        BattleLib.NFTState memory _target = nftstat[
                            _tempAction.targetid
                        ];
                        if (_skill.effect == BattleLib.EffectType.DAMAGE) {
                            (, uint256 _t) = SafeMath.trySub(
                                uint256(_target.hp),
                                uint256(_target.armor) <=
                                    uint256(_stat.strength)
                                    ? uint256(_stat.strength - _target.armor)
                                    : 0
                            );
                            nftstates[_tempAction.targetid].hp = int(_t);
                        } else if (
                            _skill.effect == BattleLib.EffectType.SELF_HEAL
                        ) {
                            nftstates[_stat.tokenid].hp += 5;
                            nftstates[_stat.tokenid].mana += 5;
                        } else if (_skill.effect == BattleLib.EffectType.HEAL) {
                            IStorage.BaseStat memory _basestat = storageNFT
                                .getBaseStat(
                                    nftstates[_tempAction.targetid].classid,
                                    nftstates[_tempAction.targetid].rare
                                );
                            if (
                                _basestat.hp >
                                nftstates[_tempAction.targetid].hp +
                                    int(_skill.value)
                            ) {
                                nftstates[_tempAction.targetid].hp = _basestat
                                    .hp;
                            } else {
                                nftstates[_tempAction.targetid].hp += int(
                                    _skill.value
                                );
                            }
                        } else if (
                            _skill.effect == BattleLib.EffectType.AOE_DAMAGE
                        ) {
                            //
                            for (uint256 i2 = 0; i2 < nftstat.length; i2++) {
                                if (nftstat[i2].owner == _target_add) {
                                    BattleLib.NFTState
                                        memory _target2 = nftstat[i2];
                                    (, uint256 _t) = SafeMath.trySub(
                                        uint256(_target2.hp),
                                        _skill.value
                                    );
                                    nftstates[_target2.tokenid].hp = int(_t);
                                }
                            }
                        }
                        
                    }
                }
            }
        }
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
            nftstat.push(
                BattleLib.NFTState(
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
                )
            );
        }
        bubbleSort(nftstat);
    }

    function bubbleSort(BattleLib.NFTState[] storage arr) internal {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j].speed < arr[j + 1].speed) {
                    BattleLib.NFTState memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }
    uint256 private nonce;
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
        revokeRole(FIGHTER_ROLE, msg.sender);
    }
}
