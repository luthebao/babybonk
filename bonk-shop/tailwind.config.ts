import type { Config } from 'tailwindcss'

const config: Config = {
    content: [
        './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
        './src/components/**/*.{js,ts,jsx,tsx,mdx}',
        './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    ],
    darkMode: 'class', // or 'media' or 'class'
    theme: {
        extend: {
            fontFamily: {
                impact: ['impact', 'sans-serif'],
                poppins: ['Poppins', 'sans-serif'],
            },
            animation: {
                'fadeInOut-4': 'fadeInOut 4s infinite',
                'fadeInOut-3': 'fadeInOut 3s infinite',
                'fadeInOut-2': 'fadeInOut 2s',
                'fadeInOut-1': 'fadeInOut 1s infinite',
            },
        },
    },
    plugins: [],
}
export default config
