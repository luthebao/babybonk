import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
    useContractRead,
    useNetwork,
    useAccount,
    usePrepareContractWrite,
    useContractWrite,
    useBalance,
} from "wagmi";

import { ADDRESS } from "@/config/address";
import { mainChain } from "@/config/connector";
import Image from "next/image";
import { formatNumber } from "@/config/utils";

const Header = () => {
    const account = useAccount()
    const network = useNetwork()
    const CONTRACTS = network.chain && !network.chain.unsupported ? ADDRESS[network.chain.id] : ADDRESS[mainChain.id]

    const nativeBalance = useBalance({
        address: account.address
    })

    const tokenBalance = useBalance({
        address: account.address,
        token: CONTRACTS.Token,
        chainId: mainChain.id
    })

    return (
        <div className="relative w-full flex flex-row justify-between items-center px-4 md:px-12 xl:px-24 h-[80px] bg-[#0000009e] backdrop-blur-xl">
            <div className="relative flex cursor-pointer text-white items-center justify-between w-full h-full">
                {/* {isConnected ? (
					<div className="flex gap-2 items-center">
						<div className="w-[24px] h-[24px] md:w-[32px] md:h-[32px] rounded-full bg-[#FF6200] flex items-center justify-center">
							<SvgWallet className="w-[14px] h-[14px] md:w-[20px] md:h-[20px]" />
						</div>

						<div className="hidden lg:flex text-[16px] font-normal ">
							{address}
						</div>
						<div className="flex lg:hidden text-[12px] md:text-[16px] font-normal ">
							{address.slice(0, 6) + ' ... ' + address.slice(38, 42)}
						</div>
						<SvgShutdown className="w-[12px] h-[12px] md:w-[16px] md:h-[16px]" />
					</div>
				) : (
					
				)} */}
                <img
                    src="/assets/images/bonkroyale.png"
                    alt="bonkroyale"
                    className="w-[60px] h-[24px] md:w-[70px] md:h-[32px]"
                />

                <div className="flex gap-2 sm:gap-6 items-center justify-center">
                    <ConnectButton showBalance={false} />

                    <div className="flex gap-2 items-center moo">
                        <img
                            src="/assets/images/babybonk.png"
                            alt="babybonk"
                            className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]"
                        />
                        <div className="text-[12px] md:text-[16px] font-normal ">
                            {tokenBalance.data ? formatNumber(tokenBalance.data.formatted) : 0}
                        </div>
                    </div>
                    <div className="flex gap-2 items-center moo">
                        <Image src={"/assets/svg/bnb.svg"} alt="" width={24} height={24} className="w-[24px] h-[24px] md:w-[32px] md:h-[32px]" />
                        <div className="text-[12px] md:text-[16px] font-normal ">
                            {nativeBalance.data ? formatNumber(nativeBalance.data.formatted, 4) : 0}
                        </div>
                    </div>
                </div>
            </div>

            <div className="flex items-center gap-2">{/* <SvgGridMenu /> */}</div>
        </div>
    );
};

export default Header;
