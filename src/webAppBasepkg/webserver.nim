import
  std / [strutils, htmlgen],
  jester, htmlgenerator,
  typedef, auth

type
  CookieTitle = enum
    ctSession = "session"
    ctNext = "next"
  NextPage = enum
    npTop = "/"
    npUserConf = "/userconf"

include "tmpl/base.tmpl"

proc getLoginUser(req: Request): LoginUser =
  ## Get login user info by session id.
  try:
    let id = req.cookies[$ctSession].parseInt
    return id.getSessionUser
  except:
    return

proc topPage(req: Request): string =
  let
    user = req.getLoginUser
  var
    param: BasePageParams
    body: seq[string]

  param.title = "Top page"
  param.header = h1("トップページ")

  if user.id == "":
    body.add ha(href: "/login", content: "ログイン").toHtml
    body.add Br
  body.add ha(href: "/userconf", content: "ユーザー設定").toHtml
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
  if req.cookies.hasKey($ctSession):
    frm.add hinput(type: tpHidden, name: "next", value: req.cookies[$ctSession]).toHtml
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
  if req.cookies.hasKey($ctSession):
    frm.add hinput(type: tpHidden, name: "next", value: req.cookies[$ctSession]).toHtml
  frm.add hinput(name: "userid", placeholder: "ユーザー名").toHtml
  frm.add Br
  frm.add hinput(type: tpPassword, name: "passwd", placeholder: "password").toHtml
  frm.add Br
  frm.add hbutton(type: tpButton, id: "newuserbtn", content: "登録").toHtml
  for line in frm.toHtml.splitLines:
    body.add line
  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc userConfPage(): string =
  "設定"


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
    resp userConfPage()
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

proc startWebServer*(port = 5000) =
  let settings = newSettings(port=Port(port))
  var jest = initJester(rt, settings=settings)
  jest.serve
