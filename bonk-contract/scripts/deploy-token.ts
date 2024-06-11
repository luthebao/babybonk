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

    // const MyToken: { address: `0x${string}` } = {
    //     "address": "0x81AA18fD3cf8B8E48B73aC5B5a42C3c4D55D4E1d"
    // }
    const MyToken = await deployer.deployContract("MyToken", [])
    await deployer.verifyContract(MyToken.address, [])

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });