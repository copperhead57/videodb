{*
  Template for IMDB Online browsing - modern
  $Id: trace.tpl,v 2.11 2005/10/13 19:30:55 andig2 Exp $
*}

<!-- Shared CSS -->
<link rel="stylesheet" href="templates/trace.css">

<!-- Template-specific CSS -->
<link rel="stylesheet" href="templates/modern/trace.css.inc"  type="text/css" />

<!-- URL + Reload -->
<table width="100%" cellspacing="0" cellpadding="0">
    <tr>
        <td>
            <table width="100%" class="tablefilter" cellspacing="5">
                <tr>
                    <td width="100%">
                        <span class="filterlink">URL: </span>
                        <a href="{$url}" target="_blank">{$url}</a>
                    </td>
                    <td align="right" nowrap>
                        {if $fetchtime}
                            <span class="filterlink">{$lang.fetchtime}: </span>{$fetchtime}s
                        {else}&nbsp;
                        {/if}
                        {if !empty($md5)} {$md5}{/if}
                    </td>
                    <td align="right">
                        <form action="trace.php" method="get" style="margin:0; padding:0;">
                            <input type="hidden" name="videodburl" value="{$url}"/>
                            <input type="hidden" name="videodbreload" value="1"/>
                            <input type="submit" value="Reload" class="button"/>
                        </form>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
<br>

<!-- IFRAME WRAPPER -->
<div class="fullframe">

    <!-- Spinner overlay -->
    <div id="iframeSpinner">Getting Requested Page…</div>

    <iframe
        id="inlineFrameIMDB"
        src="trace.php?iframe=2&videodburl={$url}">
    </iframe>
</div>

<br>

<!-- URL Sync Script -->
<script>
    document.addEventListener("DOMContentLoaded", function () {
        const iframe = document.getElementById("inlineFrameIMDB");

        const openBtn = document.querySelector("a[target='_blank']");
        const reloadForm = document.querySelector("form[action='trace.php']");
        const reloadInput = reloadForm.querySelector("input[name='videodburl']");

        function updateButtons() {
            try {
                const fullUrl = iframe.contentWindow.location.href;

                const match = fullUrl.match(/videodburl=([^&]+)/);
                if (!match) return;

                const imdbUrl = decodeURIComponent(match[1]);

                openBtn.href = imdbUrl;
                openBtn.textContent = imdbUrl;

                reloadInput.value = imdbUrl;

            } catch (e) {
                // IMDb cross-origin → ignore
            }
        }

        iframe.addEventListener("load", updateButtons);
    });
</script>

<!-- Shared spinner/navigation logic -->
<script src="./javascript/trace.js"></script>
