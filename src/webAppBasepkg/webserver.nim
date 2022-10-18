import
  jester

proc topPage(): string =
  "Top page"

router rt:
  get "/":
    resp topPage()

proc startWebServer*(port = 5000) =
  let settings = newSettings(port=Port(port))
  var jest = initJester(rt, settings=settings)
  jest.serve
