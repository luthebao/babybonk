
export function isValidHttpUrl(string: string) {
    let url;
    try {
        url = new URL(string);
    } catch (_) {
        return false;
    }
    return url.protocol === "http:" || url.protocol === "https:";
}

export function uriToHttp(uri?: string): string[] {
    if (uri) {
        const protocol = uri.split(':')[0].toLowerCase()
        switch (protocol) {
            case 'https':
                return [uri]
            case 'http':
                return ['https' + uri.substring(4), uri]
            case 'ipfs':
                const hash = uri.match(/^ipfs:(\/\/)?(.*)$/i)?.[2]
                return [`https://cloudflare-ipfs.com/ipfs/${hash}/`, `https://ipfs.io/ipfs/${hash}/`]
            case 'ipns':
                const name = uri.match(/^ipns:(\/\/)?(.*)$/i)?.[2]
                return [`https://cloudflare-ipfs.com/ipns/${name}/`, `https://ipfs.io/ipns/${name}/`]
            default:
                return [`https://ui-avatars.com/api/?rounded=true&size=150&name=${uri}&length=3&background=131929&color=fff&font-size=0.33`]
        }
    }
    return ['https://ui-avatars.com/api/?rounded=true&size=150&name=UNK&length=3&background=131929&color=fff&font-size=0.33']
}

export function formatNumber(number: string, max: number = 7): string {
    const [left, right] = number.split('.');
    const formattedLeft = (left).replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,');

    const formattedNum = right ? `${formattedLeft}.${right.slice(0, max)}` : formattedLeft;
    return formattedNum
    // return number.replace(/(?<!\..*)(\d)(?=(?:\d{3})+(?:\.|$))/g, '$1,')
}

export function devide(a: bigint, b: bigint): Number {
    return Number(a * BigInt(1000000000000000) / b) / 1000000000000000
}

export function formatInputNumber(number: string): string {
    return number.replace(/[^0-9,.]/g, '').replace(",", ".")
}


export function formatCurrency(n: number | string) {
    if (Number(n) >= 1000000000) {
        return (Number(n) / 1000000000).toFixed(1).replace(/\.0$/, '') + 'B';
    }
    if (Number(n) >= 1000000) {
        return (Number(n) / 1000000).toFixed(1).replace(/\.0$/, '') + 'M';
    }
    if (Number(n) >= 1000) {
        return (Number(n) / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
    }
    return Number(n).toString();
}