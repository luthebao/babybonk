import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
    return (
        <Html lang="en">
            <Head>
                <meta charSet="utf-8" />
                <link rel="icon" href="/logo.png" />
                <meta name="theme-color" content="#000000" />
                {/* <meta name="description" content="Web site created using create-react-app" /> */}
                {/* <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css" /> */}
                {/* <link rel="stylesheet" href="assets/fonts/Genotics/stylesheet.css" /> */}
            </Head>
            <body>
                <Main />
                <NextScript />
            </body>
        </Html>
    )
}
