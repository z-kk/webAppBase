window.addEventListener('load', function() {
    select("#newuserbtn").addEventListener('click', function() {
        let fd = new FormData(select("#newuserfrm"));
        fetch("/newuser", {
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
                alert(data.err);
            }
        });
    });
});
