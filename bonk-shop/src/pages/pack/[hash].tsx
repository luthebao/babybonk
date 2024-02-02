import { useRouter } from "next/router"
import { Fragment, useEffect, useState } from "react"
import { Hash } from "viem"

interface NFTResult {
    tokenid: number
    image: string
    rare: string
}


export default function Pack() {

    const router = useRouter()
    const { hash } = router.query
    const transactionHash = hash as Hash
    const [result, setResult] = useState<NFTResult[]>([])

    console.log("transactionHash", transactionHash)

    const fetchNFTs = async (hash: Hash) => {
        const get_nfts = await fetch(`/api/buypack/${hash}`)
        const res = await get_nfts.json()
        if (res.result.length > 0) {
            setResult(res.result)
            // (res.result as NFTResult[]).forEach(element => {
            //     fetch(element.image).then(() => {
            //         if (!result.map(val => val.tokenid).includes(element.tokenid)) {
            //             setResult((prev) => [...prev, element])
            //         }
            //     })
            // });
        } else {
            setTimeout(async () => fetchNFTs(hash), 2000)
        }
    }

    useEffect(() => {
        if (transactionHash) {
            setResult([])
            fetchNFTs(transactionHash)
        }
    }, [transactionHash])


    return (
        <Fragment>
            {result.length > 0 ? <div className={"w-full h-full relative bg-transparent flex flex-col justify-center items-center min-h-[calc(100vh-80px)]"} id="review">
                <div className="bg-[#161616] rounded-[4px] m-[32px] flex flex-col relative max-h-[calc(100%_-_64px] max-w-full w-[85vw] px-[20px] md:px-[40px] py-[20px]">
                    <div className="grid grid-cols-8 sm:grid-cols-9 md:grid-cols-10 justify-center gap-x-0 gap-y-4 md:gap-y-6 lg:gap-y-10 mx-auto mt-8">
                        {
                            result.filter(({ tokenid }, index) => !result.map((val) => val.tokenid).includes(tokenid, index + 1)).map(val => (
                                <div className="flex flex-col items-center col-span-4 sm:col-span-3 md:col-span-2 fadeIn">
                                    <img
                                        key={val.tokenid}
                                        src={val.image}
                                        className={``}
                                    />
                                    <div className="flex justify-center">{val.rare}</div>
                                </div>
                            ))
                        }
                    </div>
                    <div className="flex items-center justify-center w-full mt-20 pb-[40px] lg:pb-[20px]">
                        <a
                            className={
                                'text-[16px] md:text-[24px] font-normal text-white px-[32px] py-[16px] bg-[#ffffff0f] hover:bg-[#FF6200] cursor-pointer font-genotics'
                            }
                            // onClick={() => router.push("/")}
                            href="/"
                        >
                            BACK TO SHOP
                        </a>
                    </div>
                </div>
            </div> : <video autoPlay loop muted playsInline className="absolute top-0 left-0 right-0 bottom-0 min-w-full min-h-full w-screen h-screen z-10 bg-cover object-cover">
                <source src={"/assets/videos/loading.mp4"} type="video/mp4" />
            </video>}
        </Fragment>
    )

}
