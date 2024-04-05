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

    const ADDRESSES = {
        Token: '0x90C7d31f29d553ea8029860A7952961eF14de1e4',
        StorageNFT: '0x80834f2f8c23Da835d4B1d9B076cC70Bf960EFc7',
        CARDNFT: '0x0C1AdEA6Bf597eb7385e090B2CC4815de1d76Bb6',
        PermanentNFT: '0xd11f16015a180294295b7F5c574f33d54c4ba988',
        ConsumableNFT: '0x5FfFB17f4ea39b28C696f75D18D407d2F55cB686',
        Packs: '0x48c1a6ECF78a14045e0842F150A672F342dd103D'
    }

    const BattleFactory = await deployer.deployContract("BattleFactory", [ADDRESSES.Token])
    await deployer.verifyContract(BattleFactory.address, [ADDRESSES.Token])

    console.log("//", hre.network.name)
    console.log("// BattleFactory:", BattleFactory.address)

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });