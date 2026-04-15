// imdb-fetch.js — Dynamic Docker Wrapper

import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.error("[DEBUG]-WRAPPER LOADED:", __filename);

// URL argument
let url = process.argv[2];
console.error("[DEBUG]-Received url:", url);

if (!url) {
    console.log(JSON.stringify({ ok: false, error: "No URL provided" }));
    process.exit(1);
}

// Force HTTPS
url = url.replace(/^http:\/\//i, "https://");
console.error("[DEBUG]-Amended url:", url);

// Host fetcher path
const hostFetcher = path.resolve(__dirname, "imdb-fetch-linux.cjs");
console.error("[DEBUG]-hostFetcher:", hostFetcher);

// Project root = 4 levels up from this file
const projectRoot = path.resolve(__dirname, "../../../..");
console.error("[DEBUG]-projectRoot:", projectRoot);

// Convert host path → container path
const containerFetcher = hostFetcher.replace(projectRoot, "/app");
console.error("[DEBUG]-containerFetcher:", containerFetcher);

// Build Docker command
const cmd = [
    "docker run --rm",
    "--shm-size=1gb",
    `-v ${projectRoot}:/app`,
    "mcr.microsoft.com/playwright:v1.58.2-jammy",
    `node "${containerFetcher}" "${url}"`
].join(" ");
console.error("[DEBUG]-EXEC CMD:", cmd);

try {
    const output = execSync(cmd, { encoding: "utf8", maxBuffer: 1024 * 1024 * 50 });
    console.log(output);
} catch (err) {
    console.log(JSON.stringify({ ok: false, error: err.message }));
}
