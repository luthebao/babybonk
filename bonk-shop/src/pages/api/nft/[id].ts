import { ADDRESS } from '@/config/address';
import { mainChain } from '@/config/connector';
import { STORAGE_ABI } from '@/utils/abis';
import type { NextApiRequest, NextApiResponse } from 'next'
import { Address, createPublicClient, http } from 'viem';
import { bsc } from 'viem/chains';

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
        // console.log(req.query.id)
        // uint256 tokenid;
        // uint256 imgid;
        // uint256 classid;
        // uint256 rare;
        const info = await publicClient.readContract({
            address: STORAGE_NFT,
            abi: STORAGE_ABI,
            functionName: "CardInfos",
            args: [BigInt(req.query.id as string)]
        })
        const stat = await publicClient.readContract({
            address: STORAGE_NFT,
            abi: STORAGE_ABI,
            functionName: "getBaseStat",
            args: [info[2], info[3]]
        })
        res.status(200).json(
            {
                "name": "BONKROYALE",
                "image": `ipfs://bafybeigszjn34i7bell7haxhhuyvqbipzvmezcphzln6yxn33ha2wlobi4/${info[2].toString()}/${info[3].toString()}/img${info[1].toString()}.png`,
                "attributes": [
                    {
                        "trait_type": "hp",
                        "value": stat.hp.toString()
                    },
                    {
                        "trait_type": "mana",
                        "value": stat.mana.toString()
                    },
                    {
                        "trait_type": "strength",
                        "value": stat.strength.toString()
                    },
                    {
                        "trait_type": "speed",
                        "value": stat.speed.toString()
                    },
                    {
                        "trait_type": "avoid",
                        "value": stat.avoid.toString()
                    },
                    {
                        "trait_type": "armor",
                        "value": stat.armor.toString()
                    }
                ],
                "description": "Welcome to the thrilling world of Bonk Royale, the cutting-edge Web3 NFT card browser game where your digital collectibles come to life! Dive into an arena where players from around the globe bring their unique NFTs into action-packed battles. Whether you’re competing against other players, facing challenging CPU opponents, or honing your skills, Bonk Royale offers an immersive experience for all."
            }
        )
    } catch (error) {
        console.log(error)
        res.status(400).json({
            "name": "BONKROYALE",
            "image": "ipfs://bafybeigszjn34i7bell7haxhhuyvqbipzvmezcphzln6yxn33ha2wlobi4/1/1/img1.png",
            "attributes": [
                {
                    "trait_type": "hp",
                    "value": 0
                },
                {
                    "trait_type": "mana",
                    "value": 0
                },
                {
                    "trait_type": "strength",
                    "value": 0
                },
                {
                    "trait_type": "speed",
                    "value": 0
                },
                {
                    "trait_type": "avoid",
                    "value": 0
                },
                {
                    "trait_type": "armor",
                    "value": 0
                }
            ],
            "description": "Welcome to the thrilling world of Bonk Royale, the cutting-edge Web3 NFT card browser game where your digital collectibles come to life! Dive into an arena where players from around the globe bring their unique NFTs into action-packed battles. Whether you’re competing against other players, facing challenging CPU opponents, or honing your skills, Bonk Royale offers an immersive experience for all."
        })
    }
}

