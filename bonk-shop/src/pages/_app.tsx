import Header from '@/components/Layout/Header/Header'
import VideoBackground from '@/components/VideoBackgound/bg'
import { wagmiChains, wagmiConfig } from '@/config/connector'
import '@/styles/globals.css'
import { RainbowKitProvider, lightTheme, midnightTheme } from '@rainbow-me/rainbowkit'
import type { AppProps } from 'next/app'
import Head from 'next/head'
import { Client, HydrationProvider } from 'react-hydration-provider'
import { WagmiConfig } from 'wagmi'
import "@rainbow-me/rainbowkit/styles.css";
import 'react-toastify/dist/ReactToastify.css';
import { ToastContainer } from 'react-toastify'

export default function App({ Component, pageProps }: AppProps) {
    return (
        <HydrationProvider>
            <Client>
                <WagmiConfig config={wagmiConfig}>
                    <RainbowKitProvider chains={wagmiChains} theme={midnightTheme({
                        accentColor: "#ffe300",
                        accentColorForeground: "black",
                        borderRadius: "medium",
                    })}>
                        <Head>
                            <title>Bonk Royale NFTs by BabyBonk</title>
                        </Head>
                        <ToastContainer
                            position="top-right"
                            autoClose={2000}
                            hideProgressBar={false}
                            newestOnTop={true}
                            closeOnClick={true}
                            rtl={false}
                            pauseOnFocusLoss
                            draggable
                            pauseOnHover
                            theme="colored"
                        />
                        <div className="App">
                            <VideoBackground />
                            <Header />
                            <Component {...pageProps} />
                        </div>

                    </RainbowKitProvider>
                </WagmiConfig>
            </Client>
        </HydrationProvider>
    )
}
