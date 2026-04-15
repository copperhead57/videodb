/**
 * Shared IMDB iframe navigation + spinner logic
 * Used by all trace.tpl templates
 */

document.addEventListener("DOMContentLoaded", function () {

    const iframe = document.getElementById("inlineFrameIMDB");
    const spinner = document.getElementById("iframeSpinner");

    if (!iframe || !spinner) return; // Template missing required elements

    
    // Spinner helpers
    function showSpinnerWithText(text) {
        spinner.textContent = text;
        spinner.style.display = "flex";
    }

    function showDefaultSpinner() {
        showSpinnerWithText("Getting Requested Page…");
    }

    // Attach click + JS navigation hooks inside iframe
    function attachNavigationHooks() {
        try {
            const win = iframe.contentWindow;
            const doc = win.document;

            // Catch ALL clicks except search box
            doc.addEventListener("click", function (e) {
                let target = e.target;

                // Ignore IMDb search box typing/clicking
                if (target.closest("input[type='text']")) return;
                if (target.closest("form.imdb-header-search__form")) return;

                // Walk up DOM tree to find link text
                let node = target;
                while (node && node !== doc) {

                    // Normal <a> link
                    if (node.tagName === "A" && node.textContent.trim()) {
                        const text = node.textContent.trim();
                        showSpinnerWithText("Getting Requested Page: " + text);
                        return;
                    }

                    // IMDb autocomplete suggestion
                    if (node.dataset && node.dataset.href) {
                        const text = node.textContent.trim() || "Selected Item";
                        showSpinnerWithText("Getting Requested Page: " + text);
                        return;
                    }

                    node = node.parentNode;
                }

                // Fallback
                showDefaultSpinner();
            });

            // JS-driven navigation (autocomplete, location.assign, etc.)
            win.onbeforeunload = () => {
                showDefaultSpinner();
            };

        } catch (e) {
            // Cross-origin → cannot attach hooks
        }
    }

    // Escape internal VideoDB pages
    iframe.addEventListener("load", () => {
        try {
            const url = iframe.contentWindow.location.href;

            if (url.includes("edit.php") || url.includes("show.php")) {
                window.location.href = url;
                return;
            }

            // trace.php stays inside iframe
            if (url.includes("trace.php")) {
                return;
            }

        } catch (e) {
            // IMDb cross-origin → ignore
        }
    });

    // Initial spinner + hook attach
    spinner.style.display = "flex"; // Show immediately

    iframe.addEventListener("load", function () {
        spinner.style.display = "none"; // Hide when loaded
        attachNavigationHooks();        // Attach click + JS hooks
    });
});