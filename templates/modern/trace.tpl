{*
  Template for IMDB Online browsing
  $Id: trace.tpl,v 2.11 2005/10/13 19:30:55 andig2 Exp $
*}

<table width="100%" cellspacing="0" cellpadding="0">
<tr><td>
    <table width="100%" class="tablefilter" cellspacing="5">
    <tr><td width="100%">
        <span class="filterlink">URL: </span><a href="{$url}" target="_blank">{$url}</a>
    </td>
    <td align="right">
        <nobr>{if $fetchtime}<span class="filterlink">{$lang.fetchtime}: </span>{$fetchtime}s{else}&nbsp;{/if}{if !empty($md5)} {$md5}{/if}</nobr>
    </td>
    <td align="right">
        <form action="trace.php" method="get">
            <input type="hidden" name="videodburl" value="{$url}"/>
            <input type="hidden" name="videodbreload" value="1"/>
            <input type="submit" value="Reload" class="button"/>
        </form>
    </td></tr>
    </table>
</td></tr>
</table>
            {*
{$page}
*}

<!-- IFRAME WRAPPER (scrolls internally) -->
<!-- IFRAME (ONLY the iframe scrolls) -->
<div style="
    width:100%;
    height:70vh;
    overflow:hidden;   /* ← IMPORTANT: wrapper does NOT scroll */
    padding:0;
    margin:0;
">
    <iframe
        id="inlineFrameIMDB"
        src="trace.php?iframe=2&videodburl={$url}"
        style="
            width:100%;
            height:100%;
            border:none;
            overflow:auto;   /* ← iframe scrolls internally */
        ">
    </iframe>
</div>

<br>

<!-- URL Sync Script -->
<script>
document.addEventListener("DOMContentLoaded", function () {
    const iframe = document.getElementById("inlineFrameIMDB");

    // Buttons/fields to update
    const openBtn = document.querySelector("a[target='_blank']");
    const reloadForm = document.querySelector("form[action='trace.php']");
    const reloadInput = reloadForm.querySelector("input[name='videodburl']");

    function updateButtons() {
        try {
            const fullUrl = iframe.contentWindow.location.href;

            // Extract ONLY the IMDb URL after videodburl=
            const match = fullUrl.match(/videodburl=([^&]+)/);
            if (!match) return;

            const imdbUrl = decodeURIComponent(match[1]);

            // Update Open in Browser button
            openBtn.href = imdbUrl;
            openBtn.textContent = imdbUrl;

            // Update Reload form hidden field
            reloadInput.value = imdbUrl;

        } catch (e) {
            // Cross-origin navigation blocks access until fully loaded
        }
    }

    iframe.addEventListener("load", updateButtons);
});
</script>
