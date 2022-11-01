self.window.addEventListener('load', function() {
    select("#loginbtn").addEventListener('click', function() {
        const fd = new FormData(select("#loginfrm"));
        fetch(appName + "login", {
            method: "POST",
            body: fd,
        }).then(response => {
            if (!response.ok) {
                throw new Error("response error");
            }
            return response.json();
        }).then(data => {
            if (data.result) {
                // ログインに成功したら次のページへ
                location.href = data.href
            } else {
                // ログインに失敗したら理由を表示
                throw new Error(data.err);
            }
        }).catch(err => {
            alert(err);
        });
    });

    select("#newuserbtn").addEventListener('click', function() {
        location.href = appName + "newuser";
    });
});
