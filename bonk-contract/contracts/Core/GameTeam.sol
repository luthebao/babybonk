// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../NFTs/Reentrancy.sol";
import "../NFTs/Storage.sol";

contract GameTeam is AccessControl, Reentrancy {
    IERC721 public cardNFT;
    IERC721 public permanentNFT;
    IERC1155 public consumeNFT;
    Storage public storageNFT;

    uint8 public teamCountMax = 5;

    // mapping or owner => tokenid[]
    mapping(address => uint256[]) public cardTeams;
    constructor(
        address _cardNFT,
        address _permanentNFT,
        address _consumeNFT,
        address _storage
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        cardNFT = IERC721(address(_cardNFT));
        permanentNFT = IERC721(address(_permanentNFT));
        consumeNFT = IERC1155(address(_consumeNFT));
        storageNFT = Storage(address(_storage));
    }

    function updateCardTeam(uint256[] calldata _tokenids) external {
        require(_tokenids.length <= teamCountMax, "invalid number of cards");
        uint256 len = _tokenids.length;
        for (
            uint256 index = 0;
            index < cardTeams[address(msg.sender)].length;

        ) {
            cardTeams[address(msg.sender)].pop();
            unchecked {
                ++index;
            }
        }
        for (uint256 index = 0; index < len; ) {
            require(
                cardNFT.ownerOf(_tokenids[index]) == msg.sender,
                "not own this nft"
            );
            cardTeams[address(msg.sender)].push(_tokenids[index]);
            unchecked {
                ++index;
            }
        }
    }

    function modifyCardTeam(
        address _user,
        uint256 _slot,
        uint256 _tokenid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_slot < teamCountMax, "reach out of max team range");
        require(
            _slot < cardTeams[address(_user)].length,
            "reach out of team range"
        );
        require(cardNFT.ownerOf(_tokenid) == address(_user));
        cardTeams[address(_user)][_slot] = _tokenid;
    }
}
