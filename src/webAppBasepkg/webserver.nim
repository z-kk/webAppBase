import
  std / [strutils, htmlgen],
  jester, htmlgenerator,
  typedef, auth

include "tmpl/base.tmpl"

proc getLoginUser(req: Request): LoginUser =
  ## Get login user info by session id.
  try:
    let id = req.cookies["session"].parseInt
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

proc userConfPage(): string =
  "設定"


router rt:
  get "/":
    resp request.topPage
  get "/login":
    resp request.loginPage
  get "/userconf":
    if not request.getLoginUser.isEnable:
      redirect ("/login")
    resp userConfPage()

proc startWebServer*(port = 5000) =
  let settings = newSettings(port=Port(port))
  var jest = initJester(rt, settings=settings)
  jest.serve
