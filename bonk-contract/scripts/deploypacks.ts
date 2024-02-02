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
        Token: '0xd31be249db60b30d047aae51ccc18d0561b75465',
        StorageNFT: '0x918433C0347351A25DF52Bd53bc27ef9f6D71072',
        CARDNFT: '0xC72ACeBF485227320400b201CB3a539827c26600',
        PermanentNFT: '0x972a378e1AE945E3CAD677717d27155A3D7D8dE7',
        ConsumableNFT: '0xA69702a2d66EA543885F696721D47250B58C8439',
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
    await (await Packs.attach(Packs.address).setPriceInfo(1, "150000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(2, "250000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(3, "500000000000000", MyToken.address)).wait(confirmnum)
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