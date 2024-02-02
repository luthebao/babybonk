// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Reentrancy.sol";

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

contract CARDNFT is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Reentrancy
{
    using Strings for uint256;
    using Strings for int;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    string private _uri =
        "ipfs://bafybeigszjn34i7bell7haxhhuyvqbipzvmezcphzln6yxn33ha2wlobi4";
    bool private useURI = false;
    IStorage public storageNFT;

    constructor(address _store) ERC721("BONKROYALE", "BONKROYALE") {
        _grantRole(DEFAULT_ADMIN_ROLE, address(msg.sender));
        _grantRole(MINTER_ROLE, address(msg.sender));
        storageNFT = IStorage(address(_store));
        useURI = true;
        _uri = "https://buypack-bonk.vercel.app/api/nft/"; // change the uri here
    }

    function toggleUseURI() external onlyRole(DEFAULT_ADMIN_ROLE) {
        useURI = !useURI;
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
        if (useURI) {
            return super.tokenURI(tokenId);
        }

        IStorage.CardInfo memory info = storageNFT.CardInfos(tokenId);
        IStorage.BaseStat memory stat = storageNFT.getBaseStat(
            storageNFT.CardInfos(tokenId).classid,
            storageNFT.CardInfos(tokenId).rare
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name":"BONKROYALE",',
                            '"image":"',
                            string(
                                abi.encodePacked(
                                    _baseURI(),
                                    "/",
                                    info.classid.toString(),
                                    "/",
                                    info.rare.toString(),
                                    "/img",
                                    info.imgid.toString(),
                                    ".png"
                                )
                            ),
                            '",',
                            '"attributes": [',
                            '{"trait_type": "hp","value": ',
                            stat.hp.toString(),
                            "},",
                            '{"trait_type": "mana","value": ',
                            stat.mana.toString(),
                            "},",
                            '{"trait_type": "strength","value": ',
                            stat.strength.toString(),
                            "},",
                            '{"trait_type": "speed","value": ',
                            stat.speed.toString(),
                            "},",
                            '{"trait_type": "avoid","value": ',
                            stat.avoid.toString(),
                            "},",
                            '{"trait_type": "armor","value": ',
                            stat.armor.toString(),
                            "},",
                            "],",
                            '"description": "BONKROYALE."',
                            "}"
                        )
                    )
                )
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
