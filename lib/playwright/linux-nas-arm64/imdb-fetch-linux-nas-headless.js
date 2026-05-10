// imdb-fetch-linux-nas-headless.js — Dynamic Docker Wrapper

import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

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
const hostFetcher = path.resolve(__dirname, "imdb-fetch-linux-nas-headless.cjs");
console.error("[DEBUG]-hostFetcher:", hostFetcher);

// Project root = 4 levels up from this file
const projectRoot = path.resolve(__dirname, "../../../..");
console.error("[DEBUG]-projectRoot:", projectRoot);

// Convert host path → container path
const containerFetcher = hostFetcher.replace(projectRoot, "/app");
console.error("[DEBUG]-containerFetcher:", containerFetcher);

// Resolve Playwright version relative to this wrapper
const pwPkgPath = path.resolve(__dirname, "node_modules/playwright/package.json");
console.error("[DEBUG]-pwPkgPath:", pwPkgPath);

let pwVersion;
try {
    pwVersion = JSON.parse(
        fs.readFileSync(pwPkgPath, "utf8")
    ).version;
} catch (err) {
    console.error("[DEBUG]-ERROR reading Playwright version:", err);
    console.log(JSON.stringify({ ok: false, error: "Playwright not installed in wrapper folder" }));
    process.exit(1);
}

console.error("[DEBUG]-Playwright version:", pwVersion);

const dockerTag = `mcr.microsoft.com/playwright:v${pwVersion}-jammy`;
console.error("[DEBUG]-Docker tag:", dockerTag);

// Build Docker command
const cmd = [
    "docker run --rm --name imdb_fetcher",
    "--shm-size=1gb",
    `-v ${projectRoot}:/app`,
    dockerTag,
    `node "${containerFetcher}" "${url}"`
].join(" ");

console.error("[DEBUG]-EXEC CMD:", cmd);

// Balanced retry logic for Docker serialization (8‑minute max wait)
//const MAX_WAIT_MS = 480000; // 8 minutes
const MAX_WAIT_MS = 540000; // 9 minutes
const INTERVAL_MS = 5000;   // check every 5 seconds
let attempts = 0;
let totalWait = 0;
let output = null;

while (totalWait < MAX_WAIT_MS) {
    attempts++;

    try {
        output = execSync(cmd, {
            encoding: "utf8",
            maxBuffer: 1024 * 1024 * 50,
            stdio: ["ignore", "pipe", "pipe"]
        });
        break; // success
    } catch (err) {
        const msg = err.stderr?.toString() || err.message || "";
        if (msg.includes("Conflict") || msg.includes("already in use") ||
            msg.includes("cannot remove a running container") || msg.includes("container is still running"))
        {
            // retry - Wait quietly — no per‑retry logging
            Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, INTERVAL_MS);
            totalWait += INTERVAL_MS;
            continue;
        }
        // Other errors → fail immediately
        console.log(JSON.stringify({ ok: false, error: msg }));
        process.exit(1);
    }
}

// Only print ONE debug line if we had to wait
if (totalWait > 0) {
    const waitedSeconds = Math.floor(totalWait / 1000);
    const waitedMinutes = (totalWait / 60000).toFixed(1);
    console.error(`[DEBUG]-Docker was busy, waited ${waitedSeconds}s (${waitedMinutes}m) over ${attempts} attempts`);
}


if (!output) {
    // Final failure: exceeded max wait
    const MAX_WAIT_SEC = Math.floor(MAX_WAIT_MS / 1000);
    const MAX_WAIT_MIN = (MAX_WAIT_MS / 60000).toFixed(1);
    console.error(`[DEBUG]-Docker busy, max wait (${MAX_WAIT_SEC}s / ${MAX_WAIT_MIN}m) exceeded`);
    console.log(JSON.stringify({
        ok: false,
        error: `Docker busy, max wait (${MAX_WAIT_SEC}s / ${MAX_WAIT_MIN}m) exceeded`
    }));
    process.exit(1);
}

// Extract last non-empty line (actual JSON)
const lines = output.split("\n").map(l => l.trim()).filter(l => l.length > 0);
const lastLine = lines[lines.length - 1];

try {
    JSON.parse(lastLine);
    console.log(lastLine);
} catch {
    console.log(JSON.stringify({ ok: false, error: "Invalid JSON from container", raw: lastLine }));
}

