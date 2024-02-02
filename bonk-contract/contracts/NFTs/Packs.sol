// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Reentrancy.sol";

interface IUniswapRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IStorage {
    struct CardInfo {
        uint256 tokenid;
        uint256 imgid;
        uint256 classid;
        uint256 rare;
    }

    function CardInfos(uint256) external view returns (CardInfo memory);

    function addCardInfo(uint256, uint256, uint256, uint256) external;

    function addPermanentInfo(uint256 _tokenid, uint256 _kind) external;
}

interface INft is IERC721 {
    function safeMint(address to) external returns (uint256);

    function getCurrentTokenId() external view returns (uint256);
}

interface IITEMConsumable is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract Packs is AccessControl, Reentrancy {
    INft public nftcard;
    INft public itemPermanent;
    IITEMConsumable public itemConsumable;
    IStorage public storeNFT;
    bool public paused = false;
    uint256[] private _kind2 = [1, 3, 5, 7];
    uint256[] private _kind3 = [2, 4, 6, 8];

    uint256[] private _rare_list = [
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        2,
        3,
        3,
        3,
        3,
        3,
        4,
        4
    ];

    uint256 private nonce = 0;

    uint256 public discount_token;

    struct GiftInfo {
        uint256 typeelm; // Type ELM:  1 = NFTs Cards | 2 = Items (Permanent / Consumable)
        uint256 count;
        uint256 raremin;
        uint256 raremax;
    }

    mapping(uint256 => GiftInfo[]) public PackInfos;
    struct PriceInfo {
        uint256 eth_amount;
        address token;
    }
    mapping(uint256 => PriceInfo) public PriceInfos;
    IUniswapRouter02 public uniswapRouter;

    constructor(
        address _nftcard,
        address _itemP,
        address _itemC,
        address _store
    ) {
        discount_token = 10;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftcard = INft(_nftcard);
        itemPermanent = INft(_itemP);
        itemConsumable = IITEMConsumable(_itemC);
        storeNFT = IStorage(_store);
        PackInfos[1].push(GiftInfo(1, 5, 1, 1));
        PackInfos[2].push(GiftInfo(1, 5, 1, 2));
        PackInfos[3].push(GiftInfo(1, 5, 1, 4));
        PackInfos[3].push(GiftInfo(2, 2, 1, 3));
        PackInfos[4].push(GiftInfo(1, 5, 2, 4));
        PackInfos[4].push(GiftInfo(2, 3, 2, 3));
    }

    function claimStuckTokens(
        address token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function setPriceInfo(
        uint256 _id,
        uint256 _eth,
        address _token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PriceInfos[_id] = PriceInfo(_eth, _token);
    }

    function getPriceInfo(
        uint256 _id
    ) public view returns (uint256 eth_amount, uint256 token_amount) {
        PriceInfo memory _price = PriceInfos[_id];
        if (_price.token != address(0)) {
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = address(_price.token);
            uint256[] memory amounts = uniswapRouter.getAmountsOut(
                _price.eth_amount,
                path
            );
            eth_amount = amounts[0];
            token_amount = (amounts[1] * (100 - discount_token)) / 100;
        } else {
            eth_amount = _price.eth_amount;
            token_amount = 0;
        }
    }

    function setNFTcard(
        address _nftcard
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftcard = INft(_nftcard);
    }

    function setUniswapRouter(
        address _router
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uniswapRouter = IUniswapRouter02(_router);
    }

    function setItemPermanent(
        address _itemP
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        itemPermanent = INft(_itemP);
    }

    function setItemConsumable(
        address _itemC
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        itemConsumable = IITEMConsumable(_itemC);
    }

    function tonglePaused() public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = !paused;
    }

    function getGiftInfo(
        uint256 packid
    ) public view returns (GiftInfo[] memory) {
        return PackInfos[packid];
    }

    function setGiftInfo(
        uint256 packid,
        GiftInfo[] calldata _giftinfo
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < PackInfos[packid].length; index++) {
            delete PackInfos[packid][index];
        }
        for (uint256 index = 0; index < _giftinfo.length; index++) {
            PackInfos[packid].push(_giftinfo[index]);
        }
    }

    function setRareList(
        uint256[] memory _rares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rare_list = _rares;
    }

    function setDiscountToken(
        uint256 discount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        discount_token = discount;
    }

    function setStoreNFT(address _store) public onlyRole(DEFAULT_ADMIN_ROLE) {
        storeNFT = IStorage(_store);
    }

    function buyPack(uint256 id, bool _useToken) public payable lock {
        require(!paused, "can not buy packs at the moment");
        GiftInfo[] memory _ginfo = getGiftInfo(id);
        require(_ginfo.length > 0, "Invalid pack");
        PriceInfo memory _price = PriceInfos[id];
        if (
            _useToken &&
            address(uniswapRouter) != address(0) &&
            _price.token != address(0)
        ) {
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = address(_price.token);
            uint256[] memory amounts = uniswapRouter.getAmountsOut(
                _price.eth_amount,
                path
            );
            require(
                (
                    IERC20(address(_price.token)).transferFrom(
                        msg.sender,
                        address(this),
                        (amounts[1] * (100 - discount_token)) / 100 // discount token
                    )
                ),
                "Invalid token amount"
            );
        } else {
            require(msg.value >= _price.eth_amount, "Invalid amount");
        }
        require(_ginfo.length > 0, "Invalid pack");
        for (uint256 y = 0; y < _ginfo.length; y += 1) {
            GiftInfo memory _gift = _ginfo[y];
            if (_gift.typeelm == 1) {
                for (uint256 z = 0; z < _gift.count; z += 1) {
                    uint256 _tokenid = nftcard.getCurrentTokenId();
                    uint256 _tempid = nftcard.safeMint(msg.sender);
                    require(_tokenid == _tempid, "The minting system is busy");
                    uint256 _classid = random(1, 4);
                    uint256 _rare = randomRare(_rare_list);
                    if (_rare >= _gift.raremin && _rare <= _gift.raremax) {
                        require(address(msg.sender) != address(0));
                    } else {
                        _rare = _gift.raremin;
                    }
                    uint256 _imgid = 1;
                    if (_rare == 1) {
                        _imgid = random(1, 165);
                    } else if (_rare == 2) {
                        _imgid = random(1, 65);
                    } else if (_rare == 3) {
                        _imgid = random(1, 15);
                    } else {
                        _imgid = random(1, 5);
                    }
                    storeNFT.addCardInfo(_tokenid, _imgid, _classid, _rare);
                    // storeNFT.addCardInfo(_tokenid, 2, 3, 3);
                }
            } else {
                uint256 _rarity = random(_gift.raremin, _gift.raremax);
                if (_rarity == 2) {
                    for (uint256 z1 = 0; z1 < _gift.count; z1 += 1) {
                        uint256 _tokenid = itemPermanent.safeMint(msg.sender);
                        storeNFT.addPermanentInfo(
                            _tokenid,
                            random(1, 4) * 2 - 1
                        );
                    }
                } else if (_rarity == 3) {
                    for (uint256 z2 = 0; z2 < _gift.count; z2 += 1) {
                        uint256 _tokenid = itemPermanent.safeMint(msg.sender);
                        storeNFT.addPermanentInfo(_tokenid, random(1, 4) * 2);
                    }
                } else {
                    for (uint256 z3 = 0; z3 < _gift.count; z3 += 1) {
                        uint256 _item_temp_id = random(1, 4);
                        itemConsumable.mint(msg.sender, _item_temp_id, 1, "");
                    }
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

    function randomRare(uint256[] memory _myArray) internal returns (uint256) {
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
}
