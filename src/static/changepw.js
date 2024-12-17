self.window.addEventListener('load', function() {
    select("#changepwbtn").addEventListener('click', function() {
        const fd = new FormData(select("#changepwfrm"));
        if (fd.get("passwd") != fd.get("pcheck")) {
            alert("パスワードが一致しません");
            select("[name='passwd']").focus();
            return;
        }
        fetch(appName + "/changepw", {
            method: "POST",
            body: fd,
        }).then(response => {
            if (!response.ok) {
                throw new Error("response error");
            }
            return response.json();
        }).then(data => {
            if (data.result) {
                // 更新に成功したら元のページへ
                location.href = appName + "/userconf"
            } else {
                // 更新に失敗したら理由を表示
                throw new Error(data.err);
            }
        }).catch(err => {
            alert(err);
        });
    });
});
