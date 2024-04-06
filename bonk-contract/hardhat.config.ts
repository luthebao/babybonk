require('dotenv').config();
import "@nomiclabs/hardhat-waffle";
import "solidity-coverage";
import "@nomicfoundation/hardhat-verify";

export default {
    defaultNetwork: "bscTestnet",
    networks: {
        goerli: {
            url: "https://rpc.ankr.com/eth_goerli",
            accounts: [
                `${process.env.PRIVATE_KEY}`
            ],
        },
        baseGoerli: {
            url: "https://goerli.base.org",
            accounts: [
                `${process.env.PRIVATE_KEY}`
            ],
        },
        arbitrum: {
            url: "https://arb1.arbitrum.io/rpc",
            accounts: [
                `${process.env.PRIVATE_KEY}`
            ],
        },
        bscMainnet: {
            url: "https://bsc-dataseed1.binance.org",
            accounts: [
                `${process.env.PRIVATE_KEY}`
            ],
        },
        bscTestnet: {
            url: "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
            accounts: [
                `${process.env.PRIVATE_KEY}`
            ],
        }
    },
    etherscan: {
        apiKey: {
            goerli: `${process.env.API_KEY_GOERLI}`,
            bscMainnet: `${process.env.API_KEY_BSCMAINNET}`,
            bscTestnet: `${process.env.API_KEY_BSCTESTNET}`,
            baseGoerli: `${process.env.API_KEY_GOERLI}`,
            lineaGoerli: `${process.env.API_KEY_LINEAGOERLI}`,
            zkEVMtestnet: `${process.env.API_KEY_ZKEVM_TESTNET}`,
            opGoerli: `${process.env.API_KEY_OPGOERLI}`,
            arbitrum: `${process.env.API_KEY_ARBITRUM}`,
        },
        customChains: [
            {
                network: "baseGoerli",
                chainId: 84531,
                urls: {
                    apiURL: "https://api-goerli.basescan.org/api",
                    browserURL: "https://goerli.basescan.org/"
                },
            },
            {
                network: "lineaGoerli",
                chainId: 59140,
                urls: {
                    apiURL: "https://api-testnet.lineascan.build/api",
                    browserURL: "https://goerli.lineascan.build/"
                },
            },
            {
                network: "zkEVMtestnet",
                chainId: 1442,
                urls: {
                    apiURL: "https://api-testnet-zkevm.polygonscan.com/api",
                    browserURL: "https://testnet-zkevm.polygonscan.com/"
                },
            },
            {
                network: "opGoerli",
                chainId: 420,
                urls: {
                    apiURL: "https://api-goerli-optimistic.etherscan.io/api",
                    browserURL: "https://goerli-optimism.etherscan.io/"
                },
            },
            {
                network: "arbitrum",
                chainId: 42161,
                urls: {
                    apiURL: "https://api.arbiscan.io/api",
                    browserURL: "https://arbiscan.io/"
                },
            },
            {
                network: "bscMainnet",
                chainId: 56,
                urls: {
                    apiURL: "https://api.bscscan.com/api",
                    browserURL: "https://bscscan.com/"
                },
            },
            {
                network: "bscTestnet",
                chainId: 97,
                urls: {
                    apiURL: "https://api-testnet.bscscan.com/api",
                    browserURL: "https://testnet.bscscan.com/"
                },
            },
        ]
    },
    solidity: {
        compilers: [
            {
                version: "0.8.20",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    },
                    viaIR: true,
                }
            },
        ]
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
};
