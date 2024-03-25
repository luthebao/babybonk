import { ABI_PACKS, NFTDetail } from '@/config/abi';
import { ADDRESS } from '@/config/address';
import { mainChain, wagmiCore } from '@/config/connector';
import { formatCurrency, formatNumber } from '@/config/utils';
import { Dialog } from '@mui/material';
import Image from 'next/image';
import { useRouter } from 'next/router';
import { Fragment, useState } from 'react'
import { FaSpinner } from 'react-icons/fa6';
import { toast } from 'react-toastify';
import { Address, ContractFunctionExecutionError, TransactionExecutionError, formatEther, formatUnits } from 'viem';
import { erc20ABI, useAccount, useBalance, useContractRead, useNetwork, useToken } from 'wagmi';

interface ERROR {
    shortMessage: string
}

const NFTItem = ({ pack }: {
    pack: NFTDetail
}) => {
    const router = useRouter()
    const account = useAccount()
    const network = useNetwork()
    const CONTRACTS = network.chain && !network.chain.unsupported ? ADDRESS[network.chain.id] : ADDRESS[mainChain.id]
    // console.log("CONTRACTS", CONTRACTS)
    const nativeBalance = useBalance({
        address: account.address,
        watch: true
    })

    const tokenBalance = useBalance({
        address: account.address,
        token: CONTRACTS.Token,
        watch: true
    })

    const token = useToken({
        address: CONTRACTS.Token,
        chainId: mainChain.id
    }).data

    const priceInfo = useContractRead({
        abi: ABI_PACKS,
        address: CONTRACTS.Packs,
        chainId: mainChain.id,
        functionName: "getPriceInfo",
        args: [BigInt(pack.id)],
        watch: true
    }).data || [BigInt(0), BigInt(0)]

    const allowance = useContractRead({
        abi: erc20ABI,
        chainId: mainChain.id,
        address: CONTRACTS.Token,
        functionName: "allowance",
        args: [account.address as Address, CONTRACTS.Packs],
        watch: true,
    }).data || BigInt(0)

    const [isHover, setIsHover] = useState(false)
    const [isOpen, setIsOpen] = useState(false)
    const [loading, setLoading] = useState(false)

    const buyPack = async (useToken: boolean) => {
        // console.log("priceInfo", priceInfo)
        if (account.isConnected && account.address && network.chain && network.chain.id === mainChain.id && priceInfo[0] > BigInt(0) && priceInfo[1] > BigInt(0)) {
            setLoading(true)
            try {
                const gas = await wagmiCore.getPublicClient().estimateContractGas({
                    address: CONTRACTS.Packs,
                    abi: ABI_PACKS,
                    functionName: "buyPack",
                    args: [
                        BigInt(pack.id),
                        useToken
                    ],
                    value: useToken ? undefined : priceInfo[0],
                    account: account.address
                })

                const write = await wagmiCore.writeContract({
                    abi: ABI_PACKS,
                    address: CONTRACTS.Packs,
                    functionName: "buyPack",
                    args: [
                        BigInt(pack.id),
                        useToken
                    ],
                    value: useToken ? undefined : priceInfo[0],
                    gas: gas * BigInt(120) / BigInt(100)
                })

                const hash = write.hash
                const wait2 = await wagmiCore.waitForTransaction({
                    confirmations: 5,
                    hash: hash
                })

                if (wait2.status === "success") {
                    router.push(`/pack/${hash}`)
                } else {
                    toast("Buy Pack Failed")
                }
            } catch (error: ERROR | any) {
                console.log(error)
                if (error instanceof TransactionExecutionError) {
                    toast(error.shortMessage)
                } else if (error instanceof ContractFunctionExecutionError) {
                    toast(error.shortMessage)
                } else if ("shortMessage" in error) {
                    toast(error.shortMessage)
                } else {
                    toast("Unknown error")
                }
            }
            setLoading(false)
        } else {
            toast(`Please connect to ${mainChain.name}`)
        }
    }

    const approve = async () => {
        if (account.isConnected && account.address && network.chain && network.chain.id === mainChain.id && priceInfo[1] > BigInt(0)) {
            setLoading(true)
            try {
                const write = await wagmiCore.writeContract({
                    abi: erc20ABI,
                    address: CONTRACTS.Token,
                    functionName: "approve",
                    args: [
                        CONTRACTS.Packs,
                        priceInfo[1]
                    ]
                })

                const hash = write.hash
                const wait2 = await wagmiCore.waitForTransaction({
                    confirmations: 2,
                    hash: hash
                })

                if (wait2.status === "success") {
                    toast("Token approved")
                } else {
                    toast("Approval failed")
                }
            } catch (error: ERROR | any) {
                console.log(error)
                if (error instanceof TransactionExecutionError) {
                    toast(error.shortMessage)
                } else if (error instanceof ContractFunctionExecutionError) {
                    toast(error.shortMessage)
                } else if ("shortMessage" in error) {
                    toast(error.shortMessage)
                } else {
                    toast("Unknown error")
                }
            }
            setLoading(false)
        } else {
            toast(`Please connect to ${mainChain.name}`)
        }
    }

    return (
        <Fragment key={pack.id}>
            <div className="relative w-full sm:w-[100%] md:w-[100%] cursor-pointer mb-10 md:mb-0"
                onMouseOver={() => setIsHover(true)}
                onMouseLeave={() => setIsHover(false)}
                onClick={() => setIsOpen(true)}
            >
                <div
                    className={`absolute top-[70px] sm:top-[80px] md:top-[30px] lg:top-[50px] ${isHover
                        ? 'right-[40px] sm:right-[25px] md:right-[15px] lg:right-[35px]'
                        : 'right-[50px] sm:right-[50px] md:right-[20px] lg:right-[40px]'
                        } font-genotics text-[40px] sm:text-[32px] md:text-[32px] z-10`}
                    style={{ transition: 'all 0.2s', color: pack.color }}
                >
                </div>
                <img
                    src={`/assets/images/${pack.image}.png`}
                    alt={pack.image}
                    className="hover:scale-[1.1] z-0"
                    style={{ transition: 'all 0.3s' }}
                />
                <div className="flex items-center justify-between mt-4">
                    <div className="flex items-center justify-between gap-1">
                        <img
                            src="/assets/images/babybonk.png"
                            className="w-[24px] h-[24px] sm:w-[24px] sm:h-[24px] md:w-[26px] md:h-[26px]"
                            alt="babybonk"
                        />
                        <div className="disc font-impact text-[16px] sm:text-[14px] md:text-[12px] lg:text-[16px]">
                            {(formatCurrency(formatUnits(priceInfo[1], token?.decimals || 9)))} BABYBONK
                        </div>
                    </div>
                    <div className="flex items-center justify-between gap-1">
                        <Image src={"/assets/svg/bnb.svg"} alt="" width={24} height={24} className="w-[24px] h-[24px] sm:w-[24px] sm:h-[24px] md:w-[26px] md:h-[26px]" />
                        <div className="font-impact text-[16px] sm:text-[14px] md:text-[12px] lg:text-[18px]">
                            {formatEther(priceInfo[0])} BNB
                        </div>
                    </div>
                </div>
            </div>
            <Dialog open={isOpen} onClose={() => {
                if (true) {
                    setIsOpen(false)
                }
            }} id="detailDialog">
                <div className="flex flex-col sm:flex-row items-center justify-between w-full packs">
                    <img
                        src={`/assets/images/${pack.image}.png`}
                        alt={pack.image}
                        className="flex sm:hidden w-[300px] packimg"
                    />
                    <div className="self-start sm:self-center">
                        <div className="wrappp">
                            <div className="head text-[32px] md:text-[48px] lg:text-[56px] font-genotics w-fit text-white">
                                {pack.title} PACK
                            </div>
                            <div className="whitetxt text-[12px] lg:text-[14px] font-poppins w-fit text-white">
                                {pack.description}
                            </div>
                        </div>

                        <div className="wrappp">
                            <div className="head text-[28px] md:text-[40px] lg:text-[44px] font-genotics w-fit text-white">
                                pack chances
                            </div>
                            <div className="whitetxt">{pack.rarities}</div>
                        </div>

                        <div className="wrappp">
                            <div className="head text-[28px] md:text-[40px] lg:text-[44px] font-genotics w-fit text-white">
                                balance
                            </div>
                            <div className="flex gap-2 items-center">
                                <img
                                    src="/assets/images/babybonk.png"
                                    alt="babybonk"
                                    className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]"
                                />
                                <div className="whitetxt text-[12px] md:text-[16px] font-normal text-white">
                                    {tokenBalance.data ? formatNumber(tokenBalance.data.formatted) : 0}
                                </div>
                            </div>
                            <div className="flex gap-2 items-center mt-4">
                                <Image src={"/assets/svg/bnb.svg"} alt="" width={24} height={24} className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]" />
                                <div className="whitetxt text-[12px] md:text-[16px] font-normal text-white">
                                    {nativeBalance.data ? formatNumber(nativeBalance.data.formatted, 4) : 0}
                                </div>
                            </div>
                        </div>
                    </div>
                    <img
                        src={`/assets/images/${pack.image}.png`}
                        alt={pack.image}
                        className="hidden sm:flex w-[160px] md:w-[250px]"
                    />
                </div>
                <div className="flex items-center justify-between w-full mt-4 mobuybtn">
                    {
                        account.isConnected && account.address && network.chain && network.chain.id === mainChain.id && priceInfo[1] > BigInt(0) && priceInfo[1] > allowance ?
                            <button
                                className="flex items-center justify-center gap-2 sm:gap-4 w-[50%] border border-[#0000003d] py-[16px] bg-[#ffffff0f] hover:bg-[#f37223] cursor-pointer"
                                onClick={approve}
                                disabled={loading}
                            >
                                <img
                                    src="/assets/images/babybonk.png"
                                    alt="babybonk"
                                    className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]"
                                />
                                {loading && <FaSpinner className={`text-[19px] text-white animate-spin`} />}
                                <div className="text-[12px] md:text-[16px] font-normal text-white">
                                    APPROVE BABYBONK
                                </div>
                            </button>
                            :
                            <button
                                className="flex items-center justify-center gap-2 sm:gap-4 w-[50%] border border-[#0000003d] py-[16px] bg-[#ffffff0f] hover:bg-[#f37223] cursor-pointer"
                                onClick={() => {
                                    buyPack(true)
                                }}
                                disabled={loading}
                            >
                                <img
                                    src="/assets/images/babybonk.png"
                                    alt="babybonk"
                                    className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]"
                                />
                                {loading && <FaSpinner className={`text-[19px] text-white animate-spin`} />}
                                <div className="text-[12px] md:text-[16px] font-normal text-white">
                                    {(formatCurrency(formatUnits(priceInfo[1], token?.decimals || 9)))} BABYBONK
                                </div>
                            </button>
                    }

                    <button
                        className="flex items-center justify-center gap-2 sm:gap-4 w-[50%] border border-[#0000003d] py-[16px] bg-[#ffffff0f] hover:bg-[#FFCE00] cursor-pointer"
                        onClick={() => {
                            buyPack(false)
                        }}
                        disabled={loading}
                    >
                        <Image src={"/assets/svg/bnb.svg"} alt="" width={24} height={24} className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]" />
                        {loading && <FaSpinner className={`text-[19px] text-white animate-spin`} />}
                        <div className="text-[12px] md:text-[16px] font-normal text-white">
                            {formatEther(priceInfo[0])} BNB
                        </div>
                    </button>
                </div>
            </Dialog>
        </Fragment>
    )
};

export default NFTItem;
