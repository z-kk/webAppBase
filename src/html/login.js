window.addEventListener('load', function() {
    select("#loginbtn").addEventListener('click', function() {
        let fd = new FormData(select("#loginfrm"));
        fetch("/login", {
            method: "POST",
            body: fd,
        }).then(response => {
            if (!response.ok) {
                throw new Error("response error");
            }
            return response.json();
        }).then(data => {
            if (data.result) {
                // $B%m%0%$%s$K@.8y$7$?$i<!$N%Z!<%8$X(B
                location.href = data.href
            } else {
                // $B%m%0%$%s$K<:GT$7$?$iM}M3$rI=<((B
                alert(data.err);
            }
        });
    });

    select("#newuserbtn").addEventListener('click', function() {
        location.href = "/newuser";
    });
});
