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

    const ROUTER_UNISWAP_V2: `0x${string}` = "0xc259d1d3476558630d83b0b60c105ae958382792"

    const MyToken: { address: `0x${string}` } = {
        "address": "0xd31be249db60b30d047aae51ccc18d0561b75465"
    }
    const ADDRESSES = {
        "StorageNFT": "0x335734bdbad6ff4c7941b9BCC319D73519CA15f7",
        "CARDNFT": "0x5803b5262608ACCeD9635DB47F0384D74A1D9e43",
        "PermanentNFT": "0x0746A82A2e3b8E95dD7E26ad012eb8A45a9daf79",
        "ConsumableNFT": "0xE75Ad34b8A7166Ed8B9C6949f2dc742d917F21bF",
        "Packs": "0xF7f8B0908b2Fd2c4fC69649C1F818f00C9A9B528",
    }

    const StorageNFT = await ethers.getContractFactory("Storage")

    const CARDNFT = await ethers.getContractFactory("CARDNFT")

    const PermanentNFT = await ethers.getContractFactory("PermanentNFT")

    const ConsumableNFT = await ethers.getContractFactory("ConsumableNFT")

    const Packs = await ethers.getContractFactory("Packs")

    console.log("//", hre.network.name)

    // console.info("grant Minter Role")
    // // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6 minter role
    // await (await CARDNFT.attach(ADDRESSES.CARDNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", ADDRESSES.Packs)).wait(confirmnum)
    // await (await PermanentNFT.attach(ADDRESSES.PermanentNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", ADDRESSES.Packs)).wait(confirmnum)
    // await (await ConsumableNFT.attach(ADDRESSES.ConsumableNFT).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", ADDRESSES.Packs)).wait(confirmnum)

    // console.info("grant Mod Role")
    // // 0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f mod role
    // await (await StorageNFT.attach(ADDRESSES.StorageNFT).grantRole("0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f", ADDRESSES.Packs)).wait(confirmnum)


    // console.info("set Price")
    // // set Price Info 
    // // Params: Id Pack, ETH Amount, Token Address
    // await (await Packs.attach(ADDRESSES.Packs).setPriceInfo(1, "150000000000000", MyToken.address)).wait(confirmnum)
    // await (await Packs.attach(ADDRESSES.Packs).setPriceInfo(2, "250000000000000", MyToken.address)).wait(confirmnum)
    // await (await Packs.attach(ADDRESSES.Packs).setPriceInfo(3, "500000000000000", MyToken.address)).wait(confirmnum)
    // await (await Packs.attach(ADDRESSES.Packs).setPriceInfo(4, "750000000000000", MyToken.address)).wait(confirmnum)

    // console.info("set Uniswap Router")
    // // set Uniswap Router
    // // Put the Router V2 address of Uniswap / pancakeswap / etc ...
    // await (await Packs.attach(ADDRESSES.Packs).setUniswapRouter(ROUTER_UNISWAP_V2)).wait(confirmnum)


    for (let index = 1; index < 5; index++) {
        console.info("TEST BUY", index)
        await (await Packs.attach(ADDRESSES.Packs).buyPackTest(index)).wait(confirmnum)
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });