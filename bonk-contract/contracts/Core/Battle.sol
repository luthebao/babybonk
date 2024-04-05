// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";
import "./BattleLib.sol";

contract Battle is AccessControl, Reentrancy {
    bytes32 public constant FIGHTER_ROLE = keccak256("FIGHTER_ROLE");
    uint256 private _nextBattleId;

    IERC20 public token_bet;
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
            require(!hasRole(FIGHTER_ROLE, msg.sender));
            require(battleinfo.status == BattleLib.BattleStatus.PENDING);
            require(battleinfo.fighter == address(0));
            require(
                token_bet.transferFrom(
                    msg.sender,
                    address(this),
                    battleinfo.betamount
                )
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
        require(battleinfo.status == BattleLib.BattleStatus.ENDED);
        require(address(msg.sender) == battleinfo.winner);
        require(
            token_bet.transfer(
                address(battleinfo.winner),
                token_bet.balanceOf(address(this))
            )
        );
    }
}
