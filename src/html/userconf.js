self.window.addEventListener('load', function() {
    select("#userconfbtn").addEventListener('click', function() {
        const fd = new FormData(select("#userlistfrm"));
        fetch(appName + "userconf", {
            method: "POST",
            body: fd,
        }).then(response => {
            if (!response.ok) {
                throw new Error("response error");
            }
            return response.json();
        }).then(data => {
            if (data.result) {
                alert("更新しました");
            } else {
                alert("更新に失敗しました\n[" + data.err + "]");
            }
        }).catch(err => {
            alert(err);
        });
    });
});
