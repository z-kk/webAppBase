function updateUsersConf(e) {
    const btn = e.target;
    btn.disabled = true;

    let data = {};
    for (row of select("#userlistfrm tbody").children) {
        let rowdata = {};
        let id = row.children[0].innerText;
        let name = "permission";
        rowdata[name] = row.querySelector("[name='" + name + "']").value;
        name = "enabled";
        rowdata[name] = row.querySelector("[name='" + name + "']").checked;

        data[id] = rowdata;
    }

    fetch(appName + "/userconf", {
        method: "POST",
        headers: {
            'Content-Type': "application/json",
        },
        body: JSON.stringify(data),
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
    }).finally(_ => {
        btn.disabled = false;
    });
}

self.window.addEventListener('load', function() {
    select("#userconfbtn").addEventListener('click', updateUsersConf);
});
