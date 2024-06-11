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

    const ROUTER_UNISWAP_V2: `0x${string}` = "0x62ff25cfd64e55673168c3656f4902bd7aa5f0f4"

    const MyToken: { address: `0x${string}` } = {
        "address": "0x525fDA3b338a53CdcE61ADa92b65ADf93E1d387A"
    }
    // const MyToken = await deployer.deployContract("MyToken", [])
    // await deployer.verifyContract(MyToken.address, [])

    const StorageNFT = await deployer.deployContract("Storage", [])
    await deployer.verifyContract(StorageNFT.address, [])

    const CARDNFT = await deployer.deployContract("CARDNFT", [StorageNFT.address])
    await deployer.verifyContract(CARDNFT.address, [StorageNFT.address])

    const PermanentNFT = await deployer.deployContract("PermanentNFT", [StorageNFT.address])
    await deployer.verifyContract(PermanentNFT.address, [StorageNFT.address])

    const ConsumableNFT = await deployer.deployContract("ConsumableNFT", [])
    await deployer.verifyContract(ConsumableNFT.address, [])

    const Packs = await deployer.deployContract("Packs", [CARDNFT.address, PermanentNFT.address, ConsumableNFT.address, StorageNFT.address])
    await deployer.verifyContract(Packs.address, [CARDNFT.address, PermanentNFT.address, ConsumableNFT.address, StorageNFT.address])

    console.log("//", hre.network.name)
    console.log("// MyToken:", MyToken.address)
    console.log("// StorageNFT:", StorageNFT.address)
    console.log("// CARDNFT:", CARDNFT.address)
    console.log("// PermanentNFT:", PermanentNFT.address)
    console.log("// ConsumableNFT:", ConsumableNFT.address)
    console.log("// Packs:", Packs.address)

    console.log({
        Token: MyToken.address,
        StorageNFT: StorageNFT.address,
        CARDNFT: CARDNFT.address,
        PermanentNFT: PermanentNFT.address,
        ConsumableNFT: ConsumableNFT.address,
        Packs: Packs.address,
    })

    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6 minter role
    console.log(`Grant Role Minter`)
    await (await CARDNFT.attach(CARDNFT.address).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)
    await (await PermanentNFT.attach(PermanentNFT.address).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)
    await (await ConsumableNFT.attach(ConsumableNFT.address).grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", Packs.address)).wait(confirmnum)

    // 0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f mod role
    console.log(`Grant Role MOD`)
    await (await StorageNFT.attach(StorageNFT.address).grantRole("0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f", Packs.address)).wait(confirmnum)

    // set Price Info 
    // Params: Id Pack, ETH Amount, Token Address
    console.log(`set Price Info`)
    await (await Packs.attach(Packs.address).setPriceInfo(1, "150000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(2, "250000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(3, "500000000000000", MyToken.address)).wait(confirmnum)
    await (await Packs.attach(Packs.address).setPriceInfo(4, "750000000000000", MyToken.address)).wait(confirmnum)

    // set Uniswap Router
    // Put the Router V2 address of Uniswap / pancakeswap / etc ...
    console.log(`set Uniswap Router`)
    await (await Packs.attach(Packs.address).setUniswapRouter(ROUTER_UNISWAP_V2)).wait(confirmnum)



}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });