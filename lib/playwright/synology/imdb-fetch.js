// imdb-fetch.js — Synology Docker Playwright Wrapper (Dynamic Root)

import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Project root = synology → playwright → lib → videodb-devcode
const projectRoot = path.resolve(__dirname, "../../..");

const url = process.argv[2];
if (!url) {
    console.log(JSON.stringify({ ok: false, error: "No URL provided" }));
    process.exit(1);
}

// Linux fetcher path INSIDE Docker
const linuxFetcher = "/app/lib/playwright/synology/imdb-fetch-linux.cjs";

//"mcr.microsoft.com/playwright:v1.45.0-jammy",
const cmd = [
    "docker run --rm",
    "--shm-size=1gb",
    `-v ${projectRoot}:/app`,
    "mcr.microsoft.com/playwright:v1.58.2-jammy",
    `node ${linuxFetcher} "${url}"`
].join(" ");

try {
    
    const output = execSync(cmd, {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 50   // 50 MB buffer
});
    
 //   const output = execSync(cmd, { encoding: "utf8" });
    console.log(output);

} catch (err) {
    console.log(JSON.stringify({
        ok: false,
        error: err.message
    }));
}