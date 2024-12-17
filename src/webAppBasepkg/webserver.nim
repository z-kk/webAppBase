import
  std / [strutils, tables, json, htmlgen],
  jester, htmlgenerator,
  auth, utils

when defined(release):
  import
    std / [os],
    submodule, nimbleInfo

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

proc getMenuStr(req: Request, activePage: Page): seq[string] =
  ## Get side menu string.
  var
    item: ha
  for page, info in Pages:
    if not info.isMenuItem:
      continue
    item = ha(href: req.uri($page), content: info.title)
    if page == activePage:
      item.class.add "is-active"
    result.add item.toHtml

proc topPage(req: Request): seq[string] =
  let
    user = req.getLoginUser

  result.add ha(href: req.uri($pgSample), content: "サンプルページ").toHtml
  result.add Br
  if user.id == "":
    result.add ha(href: req.uri($pgLogin), content: "ログイン").toHtml
    result.add Br
  result.add ha(href: req.uri($pgUserConf), content: "ユーザー設定").toHtml
  result.add Br
  result.add hbutton(type: tpButton, id: "popupbtn", content: "popup sample").toHtml

  # Popup
  result.add hdiv(id: "lay").toHtml
  result.add hdiv(id: "pop", content: "Popup sample").toHtml

proc loginPage(req: Request): seq[string] =
  include "tmpl/login.tmpl"
  let
    user = req.getLoginUser
  var
    next: string

  if req.cookies.hasKey($ctNext):
    next = hinput(type: tpHidden, name: "next", value: req.cookies[$ctNext]).toHtml

  return loginPageBody(user.id, next).splitLines

proc newUserPage(req: Request): seq[string] =
  include "tmpl/newUser.tmpl"
  var
    next: string

  if req.cookies.hasKey($ctNext):
    next = hinput(type: tpHidden, name: "next", value: req.cookies[$ctNext]).toHtml

  return newUserPageBody(next).splitLines

proc usersTable(req: Request): string =
  let
    user = req.getLoginUser

  # Master, Ownerはユーザー管理テーブルを表示
  if user.permission in [pmMaster, pmOwner]:
    let users = user.permission.getAuthUsers
    var
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

    return tbl.toHtml

proc userConfPage(req: Request): seq[string] =
  include "tmpl/userConf.tmpl"
  let
    user = req.getLoginUser
    tbl = req.usersTable

  return userConfPageBody(user.id, req.uri($pgChangePw), tbl).splitLines

proc changepwPage(req: Request): seq[string] =
  include "tmpl/changepw.tmpl"
  let
    user = req.getLoginUser

  return changepwPageBody(user.id, req.uri($pgUserConf)).splitLines

proc samplePage(req: Request): seq[string] =
  include "tmpl/sample.tmpl"
  let
    user = req.getLoginUser

  return samplePageBody(user).splitLines

proc makePage(req: Request, page: Page): string =
  var
    param = req.newParams
  param.title = AppTitle
  param.sidemenu = getMenuStr(req, page)

  case page
  of pgTop:
    param.header = @[h1("トップページ")]
    param.lnk.add req.newLink("/popup.css").toHtml
    param.body = req.topPage
    param.script.add req.newScript("/popup.js").toHtml
    param.script.add req.newScript("/top.js").toHtml
  of pgLogin:
    param.title &= " - login"
    param.header = @[h1("ログイン")]
    param.body = req.loginPage
    param.script.add req.newScript("/login.js").toHtml
  of pgNewUser:
    param.header = @[h1("新規登録")]
    param.body = req.newUserPage
    param.script.add req.newScript("/newuser.js").toHtml
  of pgUserConf:
    param.header = @[h1("ユーザー設定")]
    param.body = req.userConfPage
    param.script.add req.newScript("/userconf.js").toHtml
  of pgChangePw:
    param.header = @[h1("パスワードを変更")]
    param.body = req.changepwPage
    param.script.add req.newScript("/changepw.js").toHtml
  of pgSample:
    param.header = @[h1("サンプルページ")]
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
  post "/userconftable":
    resp request.usersTable
  post "/changepw":
    let user = request.getLoginUser
    resp changeUserPass(user.id, request.formData["oldpasswd"].body, request.formData["passwd"].body)

proc startWebServer*(port: int, appName = "") =
  let settings =
    when defined(release):
      if useLocalDir:
        newSettings(Port(port), appName = appName)
      else:
        newSettings(Port(port), getConfigDir() / AppName / "public", appName)
    else:
      newSettings(Port(port), appName = appName)
  var jest = initJester(rt, settings=settings)
  jest.serve
