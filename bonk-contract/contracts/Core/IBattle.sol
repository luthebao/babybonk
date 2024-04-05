// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./BattleLib.sol";

interface IBattle {
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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function claimTokenWinner() external;

    function curruntTurnId() external view returns (uint256);

    function decodeTInfo(
        bytes memory _actionsData
    ) external pure returns (BattleLib.TurnAction[] memory actions);

    function encodeTInfo(
        BattleLib.TurnAction[] memory _actions
    ) external pure returns (bytes memory);

    function exitBattle() external;

    function getBattleInfo()
        external
        view
        returns (BattleLib.BattleInfo memory);

    function initBattleInfo(BattleLib.BattleInfo memory _info) external;

    function isConfirmed(uint256, address) external view returns (bool);

    function joinBattle() external;

    function maxTimeCurrentTurn() external view returns (uint256);

    function signTurn(bytes memory _turninfo) external;

    function starttime() external view returns (uint256);

    function token_bet() external view returns (address);

    function turnSignData(uint256) external view returns (bytes memory);

    function turnSigned(uint256, address) external view returns (bool);
}
