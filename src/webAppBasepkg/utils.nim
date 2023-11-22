import
  jester, htmlgenerator

type
  BasePageParams* = object
    title*: string
    lnk*: seq[string]
    header*: seq[string]
    sidemenu*: seq[string]
    body*: seq[string]
    footer*: seq[string]
    script*: seq[string]
    appName*: string

proc uri*(request: Request, address = ""): string =
  ## Create a URI without `request.host` and `request.port`
  uri(address, false)

proc newParams*(req: Request): BasePageParams =
  result.appName = req.appName

proc newLink*(req: Request, path = ""): hlink =
  newLink(req.uri(path))

proc newScript*(req: Request, path = ""): hscript =
  newScript(req.uri(path))
