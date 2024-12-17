function select(selector) {
    return document.querySelector(selector);
}

function selectAll(selector) {
    return document.querySelectorAll(selector);
}

function hide(e) {
    e.style.display = "none";
}

function show(e) {
    e.style.display = "";
}

function getDateString(date) {
    const y = date.getFullYear();
    let m = date.getMonth() + 1;
    let d = date.getDate()

    m = ("0" + m).slice(-2);
    d = ("0" + d).slice(-2);

    return y + "-" + m + "-" + d;
}
