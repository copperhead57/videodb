// imdb-fetch.js — Docker Playwright Wrapper (Dynamic Root, No Hardcoded Folder Names)

import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Project root = go 3 levels up from this wrapper
const projectRoot = path.resolve(__dirname, "../../..");

// URL argument
const url = process.argv[2];
if (!url) {
    console.log(JSON.stringify({ ok: false, error: "No URL provided" }));
    process.exit(1);
}

// Compute fetcher path dynamically (same folder as this wrapper)
const linuxFetcherHost = path.resolve(__dirname, "imdb-fetch-linux.cjs");

// Convert to POSIX path inside Docker
const linuxFetcher = "/app/" + path.relative(projectRoot, linuxFetcherHost).replace(/\\/g, "/");

// Build Docker command
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
        maxBuffer: 1024 * 1024 * 50
    });
    console.log(output);
} catch (err) {
    console.log(JSON.stringify({
        ok: false,
        error: err.message
    }));
}