# Playwright Headful Environment (Linux/macOS + Windows)
Unified Runtime Architecture • Persistent Profile • Project‑Local HOME

This project includes a fully self‑contained Playwright headful environment that works consistently across:
- Linux (native Apache, www‑data)
- Linux (XAMPP, daemon)
- macOS
- Windows

No system‑level browser installation is required.  
All runtime state is stored inside the project.

--------------------------------------------------------------------------------
📁 Folder Structure
--------------------------------------------------------------------------------

lib/playwright/
    linux-mac/
        chrome-profile/      ← Persistent browser profile (same as Windows)
        chrome-home/         ← Chromium HOME (Crashpad + XDG dirs)
        xvfb.sh              ← Headful wrapper for Linux/mac
        imdb-fetch-unix.mjs  ← Persistent-context fetcher
        linux/
            browsers/        ← Playwright browser binaries
        mac/
            browsers/        ← Playwright browser binaries

    windows/
        chrome-profile/      ← Windows persistent profile
        imdb-fetch-win.mjs   ← Windows persistent-context fetcher

--------------------------------------------------------------------------------
🧠 Why This Architecture Exists
--------------------------------------------------------------------------------

Linux/mac headful Chromium requires:
- a writable HOME directory
- Crashpad database
- XDG directories
- persistent profile (for stability + WAF bypass)

Windows already has these by default.  
Linux/mac under Apache does not.

So we provide them inside the project:

chrome-profile/  
    Persistent browser profile (cookies, sessions, WAF tokens).

chrome-home/  
    Chromium HOME containing:
        .config/Crashpad/
        .cache/
        .local/share/

This prevents:
- chrome_crashpad_handler: --database is required
- forced --no-startup-window
- instant Chromium crashes under www‑data

--------------------------------------------------------------------------------
🛠 Installation (Linux/macOS)
--------------------------------------------------------------------------------

Run:

    ./pw-02B-install-playwright.sh

This script:
1. Verifies Node
2. Ensures package.json exists
3. Installs Playwright
4. Installs Playwright browsers
5. Installs GUI dependencies (Linux only)
6. Creates runtime folders:
       chrome-profile/
       chrome-home/
7. Runs verification

--------------------------------------------------------------------------------
🧹 Cleaning Runtime Caches (non-destructive)
--------------------------------------------------------------------------------

    ./pw-03B-clean-cache-only.sh

This removes:
- browser caches
- GPUCache
- Code Cache
- chrome-home/.cache

But keeps:
- cookies
- sessions
- WAF tokens
- persistent profile

--------------------------------------------------------------------------------
❌ Uninstalling Playwright
--------------------------------------------------------------------------------

    ./pw-03A-uninstall-playwright.sh

This removes:
- Playwright npm packages
- Playwright browsers
- chrome-profile/
- chrome-home/
- (optional) node_modules + package-lock.json

--------------------------------------------------------------------------------
🧪 Verification
--------------------------------------------------------------------------------

    ./pw-01-verify.sh

Checks:
- Node + npm
- Playwright packages
- Browser binaries
- chrome-profile/
- chrome-home/
- Crashpad + XDG dirs
- GTK/X11/NSS (Linux)

--------------------------------------------------------------------------------
🖥 Headful Mode (Linux/macOS)
--------------------------------------------------------------------------------

All headful commands must run through:

    ./xvfb.sh <command>

Example:

    ./xvfb.sh node imdb-fetch-unix.mjs "https://www.imdb.com/title/tt0111161/"

xvfb.sh automatically sets:

    HOME=chrome-home/
    XDG_CONFIG_HOME=chrome-home/.config
    XDG_CACHE_HOME=chrome-home/.cache
    XDG_DATA_HOME=chrome-home/.local/share

This ensures Chromium launches correctly under www‑data.

--------------------------------------------------------------------------------
🌐 Linux/macOS Fetcher (Persistent Profile)
--------------------------------------------------------------------------------

    node imdb-fetch-unix.mjs <url>

Uses:
- persistent profile: chrome-profile/
- Chromium HOME: chrome-home/
- correct Chromium executable path (Linux + macOS)

--------------------------------------------------------------------------------
🪟 Windows Fetcher (Persistent Profile)
--------------------------------------------------------------------------------

    node imdb-fetch-win.mjs <url>

Uses:
- persistent profile: chrome-profile/
- Windows Chromium path
- no Xvfb required

--------------------------------------------------------------------------------
🧩 Cross‑Platform Summary
--------------------------------------------------------------------------------

Component              Linux/mac             Windows
------------------------------------------------------------
Persistent profile     chrome-profile/       chrome-profile/
Chromium HOME          chrome-home/          Windows HOME
Crashpad DB            chrome-home/.config   Built-in
Headful wrapper        xvfb.sh               Not needed
Fetcher                imdb-fetch-unix.mjs   imdb-fetch-win.mjs

Everything is now unified and predictable.

--------------------------------------------------------------------------------
📌 .gitignore
--------------------------------------------------------------------------------

Ensure these are ignored:

    chrome-profile/
    chrome-home/
    linux/browsers/
    mac/browsers/
    node_modules/
    package-lock.json

--------------------------------------------------------------------------------
🎉 Your Playwright environment is now fully unified
--------------------------------------------------------------------------------

- No XAMPP vs native Apache split
- No environment-specific hacks
- No crashpad errors
- No --no-startup-window
- No temporary profiles
- Fully portable
- Fully contributor‑friendly
