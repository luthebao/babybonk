// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";

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
    }
}

contract Battle is AccessControl, Reentrancy {
    bytes32 public constant FIGHTER_ROLE = keccak256("FIGHTER_ROLE");
    uint256 private _nextBattleId;

    IERC20 public token_bet;
    BattleFactory public factory;
    BattleLib.BattleInfo private battleinfo;
    uint256 private roundtime = 2 minutes;
    uint256 public starttime;

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

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => uint256) public numConfirm;

    constructor(address bet_token) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        token_bet = IERC20(bet_token);
        factory = BattleFactory(msg.sender);
    }

    function initBattleInfo(
        BattleLib.BattleInfo calldata _info
    ) external onlyRole(DEFAULT_ADMIN_ROLE) lock {
        require(battleinfo.owner == address(0), "already init");
        battleinfo = _info;
        grantRole(FIGHTER_ROLE, battleinfo.owner);
    }

    function getBattleInfo() public view returns (BattleLib.BattleInfo memory) {
        return battleinfo;
    }

    function joinBattle() external lock {
        require(
            !hasRole(FIGHTER_ROLE, msg.sender),
            "you are already in battle"
        );
        require(
            battleinfo.status == BattleLib.BattleStatus.PENDING,
            "battle already started"
        );
        require(
            battleinfo.fighter == address(0),
            "already has fighter in battle"
        );
        require(
            token_bet.transferFrom(
                msg.sender,
                address(this),
                battleinfo.betamount
            ),
            "transfer token to battle failed"
        );
        grantRole(FIGHTER_ROLE, msg.sender);
        battleinfo.fighter = address(msg.sender);
        battleinfo.status = BattleLib.BattleStatus.STARTED;
        starttime = block.timestamp;

        emit BattleStart(
            battleinfo.battleid,
            battleinfo.owner,
            battleinfo.fighter,
            starttime
        );
    }

    function exitBattle() external lock onlyRole(FIGHTER_ROLE) {
        require(
            battleinfo.status != BattleLib.BattleStatus.ENDED,
            "battle ended"
        );
        if (battleinfo.status == BattleLib.BattleStatus.STARTED) {
            if (battleinfo.owner == address(msg.sender)) {
                battleinfo.winner = battleinfo.fighter;
            } else {
                battleinfo.winner = address(msg.sender);
            }
            emit BattleStop(
                battleinfo.battleid,
                battleinfo.owner,
                battleinfo.fighter,
                battleinfo.winner
            );
        } else if (battleinfo.status == BattleLib.BattleStatus.PENDING) {
            require(address(msg.sender) == battleinfo.owner);
            battleinfo.winner = address(msg.sender);
        }

        battleinfo.status = BattleLib.BattleStatus.ENDED;
        revokeRole(FIGHTER_ROLE, msg.sender);
    }

    function claimTokenWinner() external lock {
        require(
            battleinfo.status == BattleLib.BattleStatus.ENDED,
            "battle not ended yet"
        );
        require(
            address(msg.sender) == battleinfo.winner,
            "battle not ended yet"
        );
        require(
            (
                token_bet.transfer(
                    address(battleinfo.winner),
                    token_bet.balanceOf(address(this))
                )
            ),
            "transfer token to winner failed"
        );
    }
}

contract BattleFactory is AccessControl, Reentrancy {
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    address[] private battleList;
    mapping(address => address[]) private battleOfOwner;

    IERC20 public token_bet;
    bool public paused;

    address public GameMaster;

    constructor(address bet_token) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        GameMaster = address(msg.sender);
        token_bet = IERC20(address(bet_token));
    }

    function createBattle(uint256 _mode, uint256 _bet_amount) external lock {
        require(!paused, "battle system is on maintenance");

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

        address battleid = address(mybattle);

        BattleLib.BattleInfo memory createdBattle = BattleLib.BattleInfo(
            battleid,
            address(msg.sender),
            address(0),
            address(0),
            _bet_amount,
            __mode,
            BattleLib.BattleStatus.PENDING
        );
        mybattle.initBattleInfo(createdBattle);

        battleOfOwner[msg.sender].push(battleid);
        battleList.push(battleid);
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
