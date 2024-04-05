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

    struct CardAction {
        uint256 tokenid;
        uint256 actionid;
    }

    struct TurnAction {
        address owner;
        CardAction[] actions;
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

    uint256 public curruntTurnId;
    uint256 public maxTimeCurrentTurn;

    // mapping from turnid => bytes
    mapping(uint256 => bytes) public turnSignData;
    // mapping from turn id => fighters => signed?
    mapping(uint256 => mapping(address => bool)) public turnSigned;
    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

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

    function encodeTInfo(
        BattleLib.TurnAction[] calldata _actions
    ) external pure returns (bytes memory) {
        return abi.encode(_actions);
    }

    function decodeTInfo(
        bytes calldata _actionsData
    ) external pure returns (BattleLib.TurnAction[] memory actions) {
        (actions) = abi.decode(_actionsData, (BattleLib.TurnAction[]));
    }

    function signTurn(
        bytes memory _turninfo
    ) external lock onlyRole(FIGHTER_ROLE) {
        uint256 myturnId = curruntTurnId;
        bytes memory turndata = turnSignData[myturnId];

        if (keccak256(turndata) == bytes32(0)) {
            turnSignData[myturnId] = _turninfo;
        } else {
            require(keccak256(turnSignData[myturnId]) == keccak256(_turninfo));
        }
        turnSigned[myturnId][address(msg.sender)] = true;

        if (
            turnSigned[myturnId][battleinfo.owner] == true &&
            turnSigned[myturnId][battleinfo.fighter] == true
        ) {
            curruntTurnId = curruntTurnId + 1;
        }
    }

    function joinBattle() external lock {
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
        }
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

    event BattleCreate(address battleid, address owner);

    constructor(address bet_token) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        GameMaster = address(msg.sender);
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

        emit BattleCreate(battleid, address(msg.sender));
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
