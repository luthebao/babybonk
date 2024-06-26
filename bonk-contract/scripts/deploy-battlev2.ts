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
        /// bsc testnet
        // Token: '0xea57226F5867a8dafc777A66ec076226aC59cC67',
        // StorageNFT: '0x85698c80F0cc04775511201f13d75BE65279Dfd6',
        // CARDNFT: '0xa6E2262d4C5DDABaE02f9F155d3DfE5bad16C99D',
        // PermanentNFT: '0xE90Fc71D77C2ae9A0546fEDC1e40827E9E686Cf6',
        // ConsumableNFT: '0xe16f9F8906031320b6E8025f5097f3eF670D6C6c',
        // Packs: '0xaF5DDAC07E86321a327f7e7e7dba82791c79FaC5',

        /// opbnb testnet
        Token: '0x525fDA3b338a53CdcE61ADa92b65ADf93E1d387A',
        StorageNFT: '0x84C921D023052834FCb3765a59330614F6F6DD8a',
        CARDNFT: '0x6BAA795D5b8c5485abE6F5a1643f16B334CA1f67',
        PermanentNFT: '0x7FdC37C5C104ACc70bfC9CbEEf46AD588B3C5740',
        ConsumableNFT: '0x784bCD64E0163692b6d0706ab73E0d1Edf3E2e48',
        Packs: '0x26E7cfb63B95057145fc0be695c0D81051d78691'
    }

    const BattleFactoryV2 = await deployer.deployContract("BattleFactoryV2", [ADDRESSES.Token, ADDRESSES.CARDNFT, "0xB27B70365Ae5F9b2aE43D9b2527b82a3355Bc038"])
    await deployer.verifyContract(BattleFactoryV2.address, [ADDRESSES.Token, ADDRESSES.CARDNFT, "0xB27B70365Ae5F9b2aE43D9b2527b82a3355Bc038"])

    // const Database = await deployer.deployContract("Database", [])
    // await deployer.verifyContract(Database.address, [])
    // await (await Database.attach(Database.address).grantRole("0x0000000000000000000000000000000000000000000000000000000000000000", "0xB27B70365Ae5F9b2aE43D9b2527b82a3355Bc038")).wait(confirmnum)

    console.log("//", hre.network.name)
    console.log("// BattleFactoryV2:", BattleFactoryV2.address)
    console.log({
        ...ADDRESSES,
        BattleFactoryV2: BattleFactoryV2.address,
        // Database: Database.address
    })

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });