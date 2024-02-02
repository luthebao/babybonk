import { ADDRESS } from '@/config/address';
import { mainChain } from '@/config/connector';
import { STORAGE_ABI } from '@/utils/abis';
import type { NextApiRequest, NextApiResponse } from 'next'
import { Address, Hash, createPublicClient, decodeEventLog, http, isAddressEqual, parseAbi } from 'viem';

const STORAGE_NFT: Address = ADDRESS[mainChain.id].StorageNFT

const publicClient = createPublicClient({
    chain: mainChain,
    transport: http()
})

export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse
) {
    try {
        const hash = req.query.hash as Hash

        const transaction = await publicClient.getTransactionReceipt({
            hash: hash
        })

        const topics = transaction.logs.filter(val => val.topics.length > 2 && isAddressEqual(val.address, ADDRESS[mainChain.id].CARDNFT) && val.topics[0] === "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" && val.topics[1] === "0x0000000000000000000000000000000000000000000000000000000000000000").map(val => val.topics)

        let result = []

        for (let index = 0; index < topics.length; index++) {
            const topic = topics[index];
            const decoded = decodeEventLog({
                abi: [
                    {
                        "anonymous": false,
                        "inputs": [
                            {
                                "indexed": true,
                                "internalType": "address",
                                "name": "from",
                                "type": "address"
                            },
                            {
                                "indexed": true,
                                "internalType": "address",
                                "name": "to",
                                "type": "address"
                            },
                            {
                                "indexed": true,
                                "internalType": "uint256",
                                "name": "tokenId",
                                "type": "uint256"
                            }
                        ],
                        "name": "Transfer",
                        "type": "event"
                    }
                ],
                // `data` should be 64 bytes, but is only 32 bytes.
                data: '0x',
                topics: topic,
                strict: false
            })
            if (decoded.args.from === "0x0000000000000000000000000000000000000000") {
                const info = await publicClient.readContract({
                    address: STORAGE_NFT,
                    abi: STORAGE_ABI,
                    functionName: "CardInfos",
                    args: [decoded.args.tokenId as bigint]
                })
                result.push({
                    tokenid: Number(decoded.args.tokenId),
                    image: `https://bafybeigszjn34i7bell7haxhhuyvqbipzvmezcphzln6yxn33ha2wlobi4.ipfs.nftstorage.link/${info[2].toString()}/${info[3].toString()}/img${info[1].toString()}.png`,
                    rare: info[3].toString() === "2" ? "Rare" : info[3].toString() === "3" ? "Ultra Rare" : info[3].toString() === "4" ? "Legendary" : "Common"
                })
            }
        }
        // [DecodeLogDataMismatch]: Data size of 32 bytes is too small for non-indexed event parameters.)
        res.status(200).json({
            result: result
        })
    } catch (error) {
        console.log(error)
        res.status(400).json({
            result: []
        })
    }
}