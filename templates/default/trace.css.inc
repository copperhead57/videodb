/* ---------------------------------------------------------
   Default Template – Trace View Overrides
   Only visual styling. All layout + logic is shared.
---------------------------------------------------------- */

/* Default table border styling */
.tableborder {
    border: 1px solid #ccc;
    background: #f9f9f9;
    padding: 6px;
    font-size: 14px;
}

/* Default filter link style */
.filterlink {
    font-weight: bold;
    color: #333;
}

/* Default button style */
input[type="submit"],
.button {
    background: #e0e0e0;
    color: #000;
    border: 1px solid #aaa;
    padding: 5px 10px;
    border-radius: 3px;
    cursor: pointer;
}

input[type="submit"]:hover,
.button:hover {
    background: #d5d5d5;
}

/* Default iframe wrapper height */
.fullframe {
    height: 80vh; /* Default template uses slightly taller viewport */
    background: #fff;
}

/* Spinner override for default theme */
#iframeSpinner {
    font-size: 18px;
    font-weight: bold;
    color: #333;
    background: rgba(255, 255, 255, 0.85);
}
