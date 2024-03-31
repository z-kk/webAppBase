self.window.addEventListener('load', function() {
    select("#newuserbtn").addEventListener('click', function() {
        const fd = new FormData(select("#newuserfrm"));
        if (fd.get("passwd") != fd.get("pcheck")) {
            alert("パスワードが一致しません");
            select("[name='passwd']").focus();
            return;
        }
        fetch(appName + "/newuser", {
            method: "POST",
            body: fd,
        }).then(response => {
            if (!response.ok) {
                throw new Error("response error");
            }
            return response.json();
        }).then(data => {
            if (data.result) {
                // 登録に成功したら次のページへ
                location.href = data.href
            } else {
                // 登録に失敗したら理由を表示
                throw new Error(data.err);
            }
        }).catch(err => {
            alert(err);
        });
    });
});
