import { Address } from "viem"
import { baseGoerli, bsc, bscTestnet, goerli } from "viem/chains"


interface POOL {
    [chainId: number]: {
        Token: Address
        StorageNFT: Address
        CARDNFT: Address
        PermanentNFT: Address
        ConsumableNFT: Address
        Packs: Address
    }
}


export const ADDRESS: POOL = {
    // [baseGoerli.id]: {
    //     Token: '0xd31be249db60b30d047aae51ccc18d0561b75465',
    //     StorageNFT: '0x918433C0347351A25DF52Bd53bc27ef9f6D71072',
    //     CARDNFT: '0xC72ACeBF485227320400b201CB3a539827c26600',
    //     PermanentNFT: '0x972a378e1AE945E3CAD677717d27155A3D7D8dE7',
    //     ConsumableNFT: '0xA69702a2d66EA543885F696721D47250B58C8439',
    //     Packs: '0x802c61d084bF7D061a9fE639Fd7Ac1db4CB062D0'
    // },
    // [bsc.id]: {
    //     Token: "0xBb2826Ab03B6321E170F0558804F2B6488C98775",
    //     StorageNFT: "0x61a22bb4883bfAbEE2Fda5fD57Acc2B0CA2Be05a",
    //     CARDNFT: "0xa599558Ef13BFEE0171b0100258384d8476FbFBA",
    //     PermanentNFT: "0xC49ec281f63c0136Fdd6542dbbebB2A14aDfA7F4",
    //     ConsumableNFT: "0x15605549f87b32ae258Cb53B97F4af73e47E8300",
    //     Packs: "0x86a6196a3c5250F4A314B88C729273124Ef0611F",
    // },
    [bscTestnet.id]: {
        Token: '0xea57226F5867a8dafc777A66ec076226aC59cC67',
        StorageNFT: '0x85698c80F0cc04775511201f13d75BE65279Dfd6',
        CARDNFT: '0xa6E2262d4C5DDABaE02f9F155d3DfE5bad16C99D',
        PermanentNFT: '0xE90Fc71D77C2ae9A0546fEDC1e40827E9E686Cf6',
        ConsumableNFT: '0xe16f9F8906031320b6E8025f5097f3eF670D6C6c',
        Packs: '0xaF5DDAC07E86321a327f7e7e7dba82791c79FaC5',
    },
}