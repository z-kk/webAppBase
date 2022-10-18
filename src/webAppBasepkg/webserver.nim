import
  std / [strutils, htmlgen],
  jester, htmlgenerator,
  typedef

include "tmpl/base.tmpl"

proc topPage(): string =
  var
    param: BasePageParams
    body: seq[string]

  param.title = "Top page"
  param.header = h1("トップページ")

  body.add ha(href: "/login", content: "ログイン").toHtml
  body.add Br
  body.add ha(href: "/userconf", content: "設定").toHtml
  param.body = body.join("\n" & ' '.repeat(8))

  return param.basePage

proc loginPage(): string =
  "ログイン"

proc userConfPage(): string =
  "設定"


router rt:
  get "/":
    resp topPage()
  get "/login":
    resp loginPage()
  get "/userconf":
    resp userConfPage()

proc startWebServer*(port = 5000) =
  let settings = newSettings(port=Port(port))
  var jest = initJester(rt, settings=settings)
  jest.serve
