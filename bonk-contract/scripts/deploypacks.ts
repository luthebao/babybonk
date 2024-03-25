import { Deployer } from "./helper";
import hre, { ethers } from "hardhat";

async function main() {
    const accounts = await hre.ethers.getSigners();
    const account_num = 0
    const confirmnum = 2

    const account = accounts[account_num];
    const network = hre.network.name
    console.log(`Submit transactions with account: ${account.address} on ${network}`)

    const deployer = new Deployer(account_num, 3)

    const prompt = require('prompt-sync')();
    const iscontinue = prompt("continue (y/n/_): ")
    if (iscontinue !== "y") {
        console.log("end")
        return
    }

    const ROUTER_UNISWAP_V2: `0x${string}` = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"

    const MyToken: { address: `0x${string}` } = {
        "address": "0x90C7d31f29d553ea8029860A7952961eF14de1e4"
    }
    const ADDRESSES = {
        Token: '0x90C7d31f29d553ea8029860A7952961eF14de1e4',
        StorageNFT: '0x80834f2f8c23Da835d4B1d9B076cC70Bf960EFc7',
        CARDNFT: '0x0C1AdEA6Bf597eb7385e090B2CC4815de1d76Bb6',
        PermanentNFT: '0xd11f16015a180294295b7F5c574f33d54c4ba988',
        ConsumableNFT: '0x5FfFB17f4ea39b28C696f75D18D407d2F55cB686',
        Packs: ''
    }

    const StorageNFT = await ethers.getContractFactory("Storage")

    const CARDNFT = await ethers.getContractFactory("CARDNFT")

    const PermanentNFT = await ethers.getContractFactory("PermanentNFT")

    const ConsumableNFT = await ethers.getContractFactory("ConsumableNFT")

    const Packs = await deployer.deployContract("Packs", [ADDRESSES.CARDNFT, ADDRESSES.PermanentNFT, ADDRESSES.ConsumableNFT, ADDRESSES.StorageNFT])
    await deployer.verifyContract(Packs.address, [ADDRESSES.CARDNFT, ADDRESSES.PermanentNFT, ADDRESSES.ConsumableNFT, ADDRESSES.StorageNFT])

    console.log("//", hre.network.name)
    console.log("// Packs:", Packs.address)

    console.info("grant Minter Role")
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6 minter role
    await (await CARDNFT.attach(ADDRESSES.CARDNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)
    await (await PermanentNFT.attach(ADDRESSES.PermanentNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)
    await (await ConsumableNFT.attach(ADDRESSES.ConsumableNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)

    console.info("grant Mod Role")
    // 0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f mod role
    await (await StorageNFT.attach(ADDRESSES.StorageNFT).grantRole("0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f", Packs.address)).wait(confirmnum)


    console.info("set Price")
    // set Price Info 
    // Params: Id Pack, ETH Amount, Token Address
    await (await Packs.attach(Packs.address).setPriceInfo(1, "15000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(2, "25000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(3, "50000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(4, "75000000000000", MyToken.address)).wait(confirmnum)

    console.info("set Uniswap Router")
    // set Uniswap Router
    // Put the Router V2 address of Uniswap / pancakeswap / etc ...
    await (await Packs.attach(Packs.address).setUniswapRouter(ROUTER_UNISWAP_V2)).wait(confirmnum)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


// bscMainnet
// router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
// MyToken: 0xBb2826Ab03B6321E170F0558804F2B6488C98775
// StorageNFT: 0x61a22bb4883bfAbEE2Fda5fD57Acc2B0CA2Be05a
// CARDNFT: 0xa599558Ef13BFEE0171b0100258384d8476FbFBA
// PermanentNFT: 0xC49ec281f63c0136Fdd6542dbbebB2A14aDfA7F4
// ConsumableNFT: 0x15605549f87b32ae258Cb53B97F4af73e47E8300
// Packs: 0x86a6196a3c5250F4A314B88C729273124Ef0611F