/* ---------------------------------------------------------
   Nexgen Template – Trace View Overrides
   Only visual styling. All layout + logic is shared.
---------------------------------------------------------- */

/* Header bar */
.row.header {
    background: #222;
    padding: 10px 0;
    margin-bottom: 10px;
}

.row.header .button-group.right li {
    margin-left: 6px;
}

/* Nexgen button style */
.button.small {
    background: #444;
    color: #fff;
    border-radius: 3px;
    padding: 6px 12px;
    font-size: 13px;
    border: none;
}

.button.small:hover {
    background: #666;
}

/* Fullframe override for nexgen */
.fullframe {
    height: calc(100vh - 80px); /* Nexgen uses full height minus header */
    background: #fff;
}

/* Spinner visual override */
#iframeSpinner {
    font-size: 20px;
    font-weight: bold;
    color: #222;
    background: rgba(255, 255, 255, 0.85);
}