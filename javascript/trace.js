/**
 * Shared IMDB iframe navigation + spinner logic
 * Used by all trace.tpl templates
 */

document.addEventListener("DOMContentLoaded", function () {

    const iframe = document.getElementById("inlineFrameIMDB");
    const spinner = document.getElementById("iframeSpinner");

    if (!iframe || !spinner) return; // Template missing required elements

    //
    // Spinner helpers
    //
    function showSpinnerWithText(text) {
        spinner.textContent = text;
        spinner.style.display = "flex";   // SHOW spinner
    }

    function showDefaultSpinner() {
        showSpinnerWithText("Getting Requested Page…");
    }

    //
    // Attach click + JS navigation hooks inside iframe
    //
    function attachNavigationHooks() {
        try {
            const win = iframe.contentWindow;
            const doc = win.document;

            // Only trigger spinner when a REAL <a> link is clicked
            doc.addEventListener("click", function (e) {
                let node = e.target;

                while (node && node !== doc) {
                    if (node.tagName === "A") {
                        showDefaultSpinner();
                        return;
                    }
                    node = node.parentNode;
                }
            });

        } catch (e) {
            // Cross-origin → cannot attach hooks
        }
    }

    //
    // Escape internal VideoDB pages
    //
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

    //
    // Initial state
    //
    spinner.style.display = "none"; // Start hidden

    //
    // When iframe loads: hide spinner + attach hooks
    //
    iframe.addEventListener("load", function () {
        spinner.style.display = "none"; // Hide when loaded
        attachNavigationHooks();        // Attach click + JS hooks
    });
});
