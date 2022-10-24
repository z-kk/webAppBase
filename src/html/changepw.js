window.addEventListener('load', function() {
    select("#changepwbtn").addEventListener('click', function() {
        let fd = new FormData(select("#changepwfrm"));
        if (fd.get("passwd") != fd.get("pcheck")) {
            alert("パスワードが一致しません");
            select("[name='passwd']").focus();
            return;
        }
        fetch("/changepw", {
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
                location.href = "/userconf"
            } else {
                // 更新に失敗したら理由を表示
                alert(data.err);
            }
        });
    });
});
