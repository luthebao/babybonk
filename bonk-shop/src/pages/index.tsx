
import { Inter } from 'next/font/google'
import NFTItem from '@/components/NFTItem/NFTItem';
import { NFTDetail } from '@/config/abi';

const inter = Inter({ subsets: ['latin'] })

const nftDatas: NFTDetail[] = [
    {
        id: 1,
        image: "essential",
        title: "ESSENTIAL",
        color: "#1DDA7B",
        babybonk: "10M",
        bnb: "0.05",
        description:
            "The ideal choice for newcomers to Bonk Royale. This basic pack includes 5 Common players (NFTs), providing a solid foundation for building your initial team. It's a great way to start your adventure, introducing you to the game mechanics and setting you on the path to eventually collecting higher rarity characters.",
        rarities: [
            <p>
                <b>Common:</b> 100%
            </p>,
        ],
    },
    {
        id: 2,
        image: "deluxe",
        title: "DELUXE",
        color: "#D3631D",
        babybonk: "50M",
        bnb: "0.1",
        description:
            "An advanced upgrade for those looking to elevate their Bonk Royale gameplay. This pack includes 5 players (NFTs), encompassing a blend of Common and Rare characters. It's an ideal choice for players seeking to enhance their team's competitiveness, providing a variety of skilled characters that can significantly strengthen and diversify your lineup.",
        rarities: [
            <p>
                <b>Common:</b> 71.74%
            </p>,
            <p>
                <b>Rare:</b> 28.26%
            </p>,
        ],
    },
    {
        id: 3,
        image: "supreme",
        title: "SUPREME",
        color: "#E2C81D",
        babybonk: "70M",
        bnb: "0.15",
        description:
            "A powerhouse choice for dominating in Bonk Royale. This formidable pack comes with 5 players (NFTs) and two items, spanning all rarity levels. It's designed for those who aim to outclass the competition, offering a diverse and potent mix of characters and gear that can decisively turn the tide in any battle.",
        rarities: [
            <p>
                <b>Common:</b> 66%
            </p>,
            <p>
                <b>Rare:</b> 26%
            </p>,
            <p>
                <b>Ultra Rare:</b> 6%
            </p>,
            <p>
                <b>Legendary:</b> 2%
            </p>,
        ],
    },
    {
        id: 4,
        image: "elite",
        title: "ELITE",
        color: "#9F40DB",
        babybonk: "100M",
        bnb: "0.25",
        description:
            "This pack stands as the pinnacle of Bonk Royale packs. This ultimate collection includes 5 players (NFTs) and 3 items, with every piece ranging from Rare to Ultra Rare or Legendary. Tailored for those seeking the best, it offers an unparalleled array of high-caliber characters and items, setting the stage for unmatched gameplay and strategic dominance.",
        rarities: [
            <p>
                <b>Rare:</b> 81.25%
            </p>,
            <p>
                <b>Ultra Rare:</b> 18.75%
            </p>,
            <p>
                <b>Legendary:</b> 6.5%
            </p>,
        ],
    },
];

export default function Home() {

    return (
        <div className="w-full h-full relative bg-transparent flex flex-col justify-center items-center min-h-[calc(100vh-80px)]" id="home">
            <div className="overlay"></div>
            <div className="w-[85%] xl:w-[70%] flex flex-col items-start justify-center maincol m-auto">
                <div className="text-[38px] lg:text-[64px] font-genotics w-fit items-center">
                    BONK ROYALE NFT SHOP
                </div>
                <div className="text-[12px] lg:text-[14px] font-poppins w-fit">
                    The perfect packs to build an ultimate team. All NFTs are usable in
                    Bonk Royale!
                </div>

                <div className="w-full flex flex-wrap items-center justify-between mt-10">
                    {nftDatas.map((data) => (
                        <div className="nftwrap" key={data.image}>
                            <NFTItem
                                pack={data}
                            />
                        </div>
                    ))}
                </div>
            </div>
            <div className="text-[12px] lg:text-[14px] font-poppins flex items-center justify-center">
                powered by BabyBonk
            </div>
        </div>
    )
}
