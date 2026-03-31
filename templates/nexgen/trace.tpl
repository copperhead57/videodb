{*
  Trace template - nexgen (Unified Baseline)
*}

<!-- {$smarty.template} -->

<!-- Shared CSS -->
<link rel="stylesheet" href="templates/trace.css">

<!-- Template-specific CSS -->
<link rel="stylesheet" href="templates/nexgen/trace.css.inc"  type="text/css" />

<div class="row header">
    <div class="small-12 columns">
        <ul class="button-group right">
            <li>
                <a href="{$url}" class="button small" target="_blank">Open in Browser</a>
            </li>
            <li>
                <a href="trace.php?iframe=1&videodburl={$url}&videodbreload=1"
                   class="button small submit">Reload</a>
            </li>
        </ul>
    </div>
</div>

<!-- IFRAME WRAPPER -->
<div class="fullframe">

    <!-- Spinner overlay -->
    <div id="iframeSpinner">Getting Requested Page…</div>

    <iframe
        id="inlineFrameIMDB"
        src="trace.php?iframe=2&videodburl={$url}">
    </iframe>

</div>

<!-- URL Sync Script -->
<script>
document.addEventListener("DOMContentLoaded", function () {
    const iframe = document.getElementById("inlineFrameIMDB");
    const reloadBtn = document.querySelector("a.submit");
    const openBtn = document.querySelector("a[target='_blank']");

    function updateButtons() {
        try {
            const fullUrl = iframe.contentWindow.location.href;

            const match = fullUrl.match(/videodburl=([^&]+)/);
            if (!match) return;

            const imdbUrl = decodeURIComponent(match[1]);

            reloadBtn.href =
                "trace.php?iframe=1&videodburl=" +
                encodeURIComponent(imdbUrl) +
                "&videodbreload=1";

            openBtn.href = imdbUrl;

        } catch (e) {
            // IMDb cross-origin → ignore
        }
    }

    iframe.addEventListener("load", updateButtons);
});
</script>

<!-- Shared spinner/navigation logic -->
<script src="./javascript/trace.js"></script>