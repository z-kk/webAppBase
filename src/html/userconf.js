function resetTable() {
    fetch(appName + "/userconftable", {
        method: "POST",
    }).then(response => {
        if (!response.ok) {
            throw new Error("response error");
        }
        return response.text();
    }).then(txt => {
        select("div.table").innerHTML = txt;
    }).catch(err => {
        alert(err);
    });
}

function updateUsersConf(e) {
    const btn = e.target;
    btn.disabled = true;

    const data = {};
    for (row of select("#userlistfrm tbody").children) {
        const rowdata = {};
        const id = row.children[0].innerText;
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
            resetTable();
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
    if (select("div.table").innerText == "") {
        hide(select("#userlistfrm"));
    } else {
        select("#userconfbtn").addEventListener('click', updateUsersConf);
    }
});
