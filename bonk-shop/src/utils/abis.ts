

export const STORAGE_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "indexed": true,
                "internalType": "bytes32",
                "name": "previousAdminRole",
                "type": "bytes32"
            },
            {
                "indexed": true,
                "internalType": "bytes32",
                "name": "newAdminRole",
                "type": "bytes32"
            }
        ],
        "name": "RoleAdminChanged",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "account",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "sender",
                "type": "address"
            }
        ],
        "name": "RoleGranted",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "account",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "sender",
                "type": "address"
            }
        ],
        "name": "RoleRevoked",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "CardInfos",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "tokenid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "imgid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "classid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "rare",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "DEFAULT_ADMIN_ROLE",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "MODERATOR",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "PermanentItems",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "tokenid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "kind",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "_imgid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "_classid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "_rare",
                "type": "uint256"
            }
        ],
        "name": "addCardInfo",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "_kind",
                "type": "uint256"
            }
        ],
        "name": "addPermanentInfo",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "basestats",
        "outputs": [
            {
                "internalType": "int256",
                "name": "hp",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "mana",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "strength",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "speed",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "avoid",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "armor",
                "type": "int256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "consumstats",
        "outputs": [
            {
                "internalType": "int256",
                "name": "hp",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "mana",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "strength",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "speed",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "avoid",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "armor",
                "type": "int256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_classid",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "_rare",
                "type": "uint256"
            }
        ],
        "name": "getBaseStat",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "int256",
                        "name": "hp",
                        "type": "int256"
                    },
                    {
                        "internalType": "int256",
                        "name": "mana",
                        "type": "int256"
                    },
                    {
                        "internalType": "int256",
                        "name": "strength",
                        "type": "int256"
                    },
                    {
                        "internalType": "int256",
                        "name": "speed",
                        "type": "int256"
                    },
                    {
                        "internalType": "int256",
                        "name": "avoid",
                        "type": "int256"
                    },
                    {
                        "internalType": "int256",
                        "name": "armor",
                        "type": "int256"
                    }
                ],
                "internalType": "struct Storage.BaseStat",
                "name": "",
                "type": "tuple"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            }
        ],
        "name": "getRoleAdmin",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "grantRole",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "hasRole",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "itemstats",
        "outputs": [
            {
                "internalType": "int256",
                "name": "hp",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "mana",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "strength",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "speed",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "avoid",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "armor",
                "type": "int256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "renounceRole",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "role",
                "type": "bytes32"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "revokeRole",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "interfaceId",
                "type": "bytes4"
            }
        ],
        "name": "supportsInterface",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "classid",
                "type": "uint256"
            },
            {
                "internalType": "int256",
                "name": "hp",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "mana",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "strength",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "speed",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "avoid",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "armor",
                "type": "int256"
            }
        ],
        "name": "updateBaseStat",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
] as const