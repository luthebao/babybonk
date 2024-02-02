// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Reentrancy.sol";

interface IStorage {
    struct PermanentItem {
        uint256 tokenid;
        uint256 kind;
    }

    function PermanentItems(
        uint256
    ) external view returns (PermanentItem memory);
}

contract PermanentNFT is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Reentrancy
{
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    string private _uri =
        "ipfs://bafybeif23t7gwfmi7y7e6esoxlku4obvnqapxczrajzn4sn5jd64wig3f4";
    IStorage public storageNFT;

    constructor(address _store) ERC721("Permanent NFT", "PN") {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        _grantRole(MINTER_ROLE, address(msg.sender));
        storageNFT = IStorage(address(_store));
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function updateURI(
        string calldata _newuri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _uri = _newuri;
    }

    function setStoreNFT(
        address _newadd
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        storageNFT = IStorage(address(_newadd));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        IStorage.PermanentItem memory info = storageNFT.PermanentItems(tokenId);

        return
            string(
                abi.encodePacked(_baseURI(), "/", info.kind.toString(), ".json")
            );
    }

    function safeMint(
        address to
    ) public lock onlyRole(MINTER_ROLE) returns (uint256 _tokenid) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _tokenid = tokenId;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    function getAllTokenOfOwner(
        address _account
    ) public view returns (uint256[] memory) {
        uint256 count = balanceOf(address(_account));
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            uint256 tokenid = tokenOfOwnerByIndex(address(_account), index);
            result[index] = tokenid;
        }
        return result;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
