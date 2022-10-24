function showPopup() {
    select("#lay").style.display = "block";
    select("#pop").style.display = "block";
}

function hidePopup() {
    hide(select("#lay"));
    hide(select("#pop"));
}

select("#lay").addEventListener('click', function() {
    hidePopup();
});

window.addEventListener('scroll', function() {
    select("#lay").style.top = this.scrollY + "px";
    select("#lay").style.left = this.scrollX + "px";

    select("#pop").style.top = window.innerHeight * 0.1 - 16 + this.scrollY + "px";
    select("#pop").style.left = window.innerWidth * 0.1 - 16 + this.scrollX + "px";
});
