import
  std / [os, strutils, tables, json, htmlgen],
  jester, htmlgenerator,
  auth, utils

type
  Page = enum
    pgTop = "/"
    pgLogin = "/login"
    pgNewUser = "/newuser"
    pgUserConf = "/userconf"
    pgChangePw = "/changepw"
    pgSample = "/sample"
  CookieTitle = enum
    ctSession = "session"
    ctNext = "next"
  ValueName = enum
    vnPermission = "permission"
    vnEnabled = "enabled"

const
  AppTitle = "webApp"
  BodyIndent = 4 * 4
  Pages: OrderedTable[Page, tuple[title: string, isMenuItem: bool]] = {
    pgTop: ("Top Page", true),
    pgLogin: ("Login", false),
    pgNewUser: ("New user", false),
    pgUserConf: ("User config", false),
    pgChangePw: ("Change password", false),
    pgSample: ("Sample", true),
  }.toOrderedTable

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
    data = req.body.parseJson
  for u in users:
    var res = u
    if $u.id notin data:
      continue
    let dat = data[$u.id]
    if $vnPermission in dat:
      res.permission = Permission(dat[$vnPermission].getStr.parseInt)
    res.isEnable = $vnEnabled in dat and dat[$vnEnabled].getBool
    if u.permission != res.permission or u.isEnable != res.isEnable:
      result.add res

proc getMenuStr(activePage: Page): string =
  ## Get side menu string.
  var
    menu: seq[string]
    item: ha
  for page, info in Pages:
    if not info.isMenuItem:
      continue
    item = ha(href: $page, content: info.title)
    if page == activePage:
      item.class.add "is-active"
    menu.add item.toHtml

  return menu.join(" $1\n$2" % [Br, ' '.repeat(BodyIndent)])

proc topPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    body: seq[string]

  body.add ha(href: req.uri($pgSample), content: "サンプルページ").toHtml
  body.add Br
  if user.id == "":
    body.add ha(href: req.uri($pgLogin), content: "ログイン").toHtml
    body.add Br
  body.add ha(href: req.uri($pgUserConf), content: "ユーザー設定").toHtml
  body.add Br
  body.add hbutton(type: tpButton, id: "popupbtn", content: "popup sample").toHtml

  # Popup
  body.add hdiv(id: "lay").toHtml
  body.add hdiv(id: "pop", content: "Popup sample").toHtml

  return body.join("\n" & ' '.repeat(BodyIndent))

proc loginPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    body: seq[string]
    frm: hform

  frm.id = "loginfrm"
  if req.cookies.hasKey($ctNext):
    frm.add hinput(type: tpHidden, name: "next", value: req.cookies[$ctNext]).toHtml
  frm.add hinput(name: "userid", title: "ユーザー名", value: user.id, placeholder: "ユーザー名").toHtml
  frm.add hinput(type: tpPassword, name: "passwd", title: "パスワード", placeholder: "password").toHtml
  frm.add hbutton(type: tpButton, id: "loginbtn", content: "ログイン").toHtml
  frm.add hbutton(type: tpButton, id: "newuserbtn", content: "新規登録").toHtml
  for line in frm.toHtml.splitLines:
    body.add line

  return body.join("\n" & ' '.repeat(BodyIndent))

proc newUserPage(req: Request): string =
  var
    body: seq[string]
    frm: hform

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

  return body.join("\n" & ' '.repeat(BodyIndent))

proc userConfPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    body: seq[string]

  var d: hdiv
  d.add hlabel(class: @["label-inline"], content: "ユーザーID:").toHtml
  d.add hlabel(class: @["label-inline"], content: user.id).toHtml
  d.add Br
  d.add ha(content: "パスワードを変更", href: req.uri($pgChangePw)).toHtml
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
      sel.name = $vnPermission
      for pm in pmGuest .. user.permission:
        var opt = hoption(value: $pm.ord, content: $pm)
        if pm == u.permission:
          opt.selected = true
        sel.add opt
      let chk = hcheckbox(name: $vnEnabled, checked: u.isEnable)

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

  return body.join("\n" & ' '.repeat(BodyIndent))

proc changepwPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    body: seq[string]
    frm: hform

  frm.id = "changepwfrm"
  frm.add hlabel(class: @["label-inline"], content: "ユーザーID:").toHtml
  frm.add hlabel(class: @["label-inline"], content: user.id).toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "oldpasswd", title: "旧パスワード", placeholder: "old password").toHtml
  frm.add hinput(type: tpPassword, name: "passwd", title: "新パスワード", placeholder: "new password").toHtml
  frm.add hinput(type: tpPassword, name: "pcheck", title: "再入力", placeholder: "再入力").toHtml
  frm.add hbutton(type: tpButton, id: "changepwbtn", content: "OK").toHtml
  for line in frm.toHtml.splitLines:
    body.add line
  body.add ha(href: req.uri($pgUserConf), content: "戻る").toHtml

  return body.join("\n" & ' '.repeat(BodyIndent))

proc samplePage(req: Request): string =
  let
    user = req.getLoginUser
  var
    body: seq[string]
    frm: hform

  if user.id == "":
    var d: hdiv
    d.add hlabel(content: "ユーザー情報なし").toHtml
    for line in d.toHtml.splitLines:
      body.add line
  else:
    body.add hlabel(class: @["label-inline", "title"], content: "ID: ").toHtml
    body.add hlabel(class: @["label-inline"], content: user.id).toHtml
    body.add Br
    body.add hlabel(class: @["label-inline", "title"], content: "Enable: ").toHtml
    body.add hlabel(class: @["label-inline"], content: $user.isEnable).toHtml
    body.add Br

  frm.id = "samplefrm"
  frm.add hinput(name: "input1", title: "input-title").toHtml
  frm.add hbutton(content: "OK").toHtml
  for line in frm.toHtml.splitLines:
    body.add line

  return body.join("\n" & ' '.repeat(BodyIndent))

proc makePage(req: Request, page: Page): string =
  var
    param = req.newParams
  param.title = AppTitle
  param.sidemenu = getMenuStr(page)

  case page
  of pgTop:
    param.header = h1("トップページ")
    param.lnk.add req.newLink("/popup.css").toHtml
    param.body = req.topPage
    param.script.add req.newScript("/popup.js").toHtml
    param.script.add req.newScript("/top.js").toHtml
  of pgLogin:
    param.title &= " - login"
    param.header = h1("ログイン")
    param.body = req.loginPage
    param.script.add req.newScript("/login.js").toHtml
  of pgNewUser:
    param.header = h1("新規登録")
    param.body = req.newUserPage
    param.script.add req.newScript("/newuser.js").toHtml
  of pgUserConf:
    param.header = h1("ユーザー設定")
    param.lnk.add req.newLink("/table.css").toHtml
    param.body = req.userConfPage
    param.script.add req.newScript("/userconf.js").toHtml
  of pgChangePw:
    param.header = h1("パスワードを変更")
    param.body = req.changepwPage
    param.script.add req.newScript("/changepw.js").toHtml
  of pgSample:
    param.header = h1("サンプルページ")
    param.lnk.add req.newLink("/sample.css").toHtml
    param.body = req.samplePage

  return param.basePage

router rt:
  get "/":
    setCookie($ctNext, $pgTop.ord)
    resp request.makePage(pgTop)
  get "/login":
    resp request.makePage(pgLogin)
  get "/newuser":
    resp request.makePage(pgNewUser)
  get "/userconf":
    if not request.getLoginUser.isEnable:
      setCookie($ctNext, $pgUserConf.ord)
      redirect uri($pgLogin, false)
    resp request.makePage(pgUserConf)
  get "/changepw":
    if not request.getLoginUser.isEnable:
      setCookie($ctNext, $pgChangePw.ord)
      redirect uri($pgLogin, false)
    resp request.makePage(pgChangePw)
  get "/sample":
    resp request.makePage(pgSample)
  post "/login":
    var res = login(request.formData["userid"].body, request.formData["passwd"].body)
    if res["result"].getBool:
      try:
        res["href"] = %uri($Page(request.formData["next"].body.parseInt), false)
      except:
        res["href"] = %uri($pgTop, false)
      setCookie($ctSession, $res["id"].getInt, httpOnly = true)
      res.delete("id")
    resp res
  post "/newuser":
    var res = addNewUser(request.formData["userid"].body, request.formData["passwd"].body)
    if res["result"].getBool:
      try:
        res["href"] = %uri($Page(request.formData["next"].body.parseInt), false)
      except:
        res["href"] = %uri($pgTop, false)
      setCookie($ctSession, $res["id"].getInt, httpOnly = true)
      res.delete("id")
    resp res
  post "/userconf":
    resp request.getParamUsers.updateAuthUsers
  post "/changepw":
    let user = request.getLoginUser
    resp changeUserPass(user.id, request.formData["oldpasswd"].body, request.formData["passwd"].body)

proc startWebServer*(port = 5000, staticDir = "", appName = "") =
  let settings =
    if staticDir != "":
      newSettings(Port(port), staticDir, appName)
    else:
      newSettings(Port(port), appName = appName)
  var jest = initJester(rt, settings=settings)
  jest.serve
