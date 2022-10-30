import
  std / [os, strutils, json, htmlgen],
  jester, htmlgenerator,
  typedef, auth

type
  CookieTitle = enum
    ctSession = "session"
    ctNext = "next"
  NextPage = enum
    npTop = "/"
    npUserConf = "/userconf"
    npChangePw = "/changepw"
  NameSuffix = enum
    nsPermission = "_perm"
    nsEnabled = "_enb"

include "tmpl/base.tmpl"

proc getLoginUser(req: Request): LoginUser =
  ## Get login user info by session id.
  try:
    let id = req.cookies[$ctSession].parseInt
    return id.getSessionUser
  except:
    return

proc getParamUsers(req: Request): seq[LoginUser] =
  ## Get users by html parameter.
  let
    user = req.getLoginUser
    users = user.permission.getAuthUsers
    data = req.formData
  for u in users:
    var res = u
    if data.hasKey(u.id & $nsPermission):
      res.permission = Permission(data[u.id & $nsPermission].body.parseInt)
    res.isEnable = data.hasKey(u.id & $nsEnabled)
    if u.permission != res.permission or u.isEnable != res.isEnable:
      result.add res

proc topPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    param: BasePageParams
    body: seq[string]

  param.title = "Top page"
  param.lnk.add newLink("/popup.css").toHtml
  param.header = h1("トップページ")
  param.script.add newScript("/popup.js").toHtml
  param.script.add newScript("/top.js").toHtml

  if user.id == "":
    body.add ha(href: "/login", content: "ログイン").toHtml
    body.add Br
  body.add ha(href: "/userconf", content: "ユーザー設定").toHtml
  body.add Br
  body.add hbutton(type: tpButton, id: "popupbtn", content: "popup sample").toHtml

  # Popup
  body.add hdiv(id: "lay").toHtml
  body.add hdiv(id: "pop", content: "Popup sample").toHtml

  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc loginPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    param: BasePageParams
    body: seq[string]
    frm: hform

  param.title = "login"
  param.header = h1("ログイン")
  param.script.add newScript("/login.js").toHtml

  frm.id = "loginfrm"
  if req.cookies.hasKey($ctNext):
    frm.add hinput(type: tpHidden, name: "next", value: req.cookies[$ctNext]).toHtml
  frm.add hinput(name: "userid", value: user.id, placeholder: "ユーザー名").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "passwd", placeholder: "password").toHtml
  frm.add Br
  frm.add hbutton(type: tpButton, id: "loginbtn", content: "ログイン").toHtml
  frm.add hbutton(type: tpButton, id: "newuserbtn", content: "新規登録").toHtml
  for line in frm.toHtml.splitLines:
    body.add line
  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc newUserPage(req: Request): string =
  var
    param: BasePageParams
    body: seq[string]
    frm: hform

  param.title = "new user"
  param.header = h1("新規登録")
  param.script.add newScript("/newuser.js").toHtml

  frm.id = "newuserfrm"
  if req.cookies.hasKey($ctNext):
    frm.add hinput(type: tpHidden, name: "next", value: req.cookies[$ctNext]).toHtml
  frm.add hinput(name: "userid", placeholder: "ユーザー名").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "passwd", placeholder: "password").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "pcheck", placeholder: "再入力").toHtml
  frm.add Br
  frm.add hbutton(type: tpButton, id: "newuserbtn", content: "登録").toHtml
  for line in frm.toHtml.splitLines:
    body.add line
  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc userConfPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    param: BasePageParams
    body: seq[string]

  param.title = "user config"
  param.lnk.add newLink("/table.css").toHtml
  param.header = h1("ユーザー設定")
  param.footer = ha(href: "/", content: "TopPage").toHtml
  param.script.add newScript("/userconf.js").toHtml

  var d: hdiv
  d.add hlabel(content: "ユーザーID:").toHtml
  d.add hlabel(content: user.id).toHtml
  d.add Br
  d.add ha(content: "パスワードを変更", href: "/changepw").toHtml
  for line in d.toHtml.splitLines:
    body.add line

  # Master, Ownerはユーザー管理テーブルを表示
  if user.permission in [pmMaster, pmOwner]:
    let users = user.permission.getAuthUsers
    var
      frm = hform(id: "userlistfrm")
      sel: hselect
      tbl: htable
      tr: htr

    # タイトル
    tr.add hth(content: "user id")
    tr.add hth(content: "permission")
    tr.add hth(content: "enabled")
    tbl.thead.add tr

    # ユーザーリストを作成
    for u in users:
      sel.options = @[]
      sel.name = u.id & $nsPermission
      for pm in pmGuest .. user.permission:
        var opt = hoption(value: $pm.ord, content: $pm)
        if pm == u.permission:
          opt.selected = true
        sel.add opt
      let chk = hcheckbox(name: u.id & $nsEnabled, checked: u.isEnable)

      tr.add htd(content: u.id)
      tr.add htd(content: sel.toHtml)
      tr.add htd(content: chk.toHtml)
      tbl.tbody.add tr

    d = hdiv(class: @["table"])
    d.add tbl.toHtml
    frm.add d.toHtml
    frm.add hbutton(type: tpButton, id: "userconfbtn", content: "OK").toHtml

    for line in frm.toHtml.splitLines:
      body.add line

  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc changepwPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    param: BasePageParams
    body: seq[string]
    frm: hform

  param.title = "change pass"
  param.header = h1("パスワードを変更")
  param.script.add newScript("/changepw.js").toHtml

  frm.id = "changepwfrm"
  frm.add hlabel(content: "ユーザーID:").toHtml
  frm.add hlabel(content: user.id).toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "oldpasswd", placeholder: "old password").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "passwd", placeholder: "new password").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "pcheck", placeholder: "再入力").toHtml
  frm.add Br
  frm.add hbutton(type: tpButton, id: "changepwbtn", content: "OK").toHtml
  for line in frm.toHtml.splitLines:
    body.add line
  body.add ha(href: "/userconf", content: "戻る").toHtml
  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

router rt:
  get "/":
    setCookie($ctNext, $npTop.ord)
    resp request.topPage
  get "/login":
    resp request.loginPage
  get "/newuser":
    resp request.newUserPage
  get "/userconf":
    if not request.getLoginUser.isEnable:
      setCookie($ctNext, $npUserConf.ord)
      redirect ("/login")
    resp request.userConfPage
  get "/changepw":
    if not request.getLoginUser.isEnable:
      setCookie($ctNext, $npChangePw.ord)
      redirect ("/login")
    resp request.changepwPage
  post "/login":
    var res = login(request.formData["userid"].body, request.formData["passwd"].body)
    if res["result"].getBool:
      try:
        res["href"] = %($NextPage(request.formData["next"].body.parseInt))
      except:
        res["href"] = %($npTop)
      setCookie($ctSession, $res["id"].getInt, httpOnly = true)
      res.delete("id")
    resp res
  post "/newuser":
    var res = addNewUser(request.formData["userid"].body, request.formData["passwd"].body)
    if res["result"].getBool:
      try:
        res["href"] = %($NextPage(request.formData["next"].body.parseInt))
      except:
        res["href"] = %($npTop)
      setCookie($ctSession, $res["id"].getInt, httpOnly = true)
      res.delete("id")
    resp res
  post "/userconf":
    resp request.getParamUsers.updateAuthUsers
  post "/changepw":
    let user = request.getLoginUser
    resp changeUserPass(user.id, request.formData["oldpasswd"].body, request.formData["passwd"].body)

proc startWebServer*(port = 5000) =
  let settings = newSettings(Port(port), getConfigDir() / getAppFilename().extractFilename / "public")
  var jest = initJester(rt, settings=settings)
  jest.serve
