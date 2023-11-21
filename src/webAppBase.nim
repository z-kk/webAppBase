import
  std / [strutils, random],
  docopt,
  webAppBasepkg / [webserver, dbtables, submodule, nimbleInfo]

type
  CmdOpt = object
    port: int
    appName: string

const
  DefaultPort = 5000

proc readCmdOpt(): CmdOpt =
  ## Read command line options.
  let doc = """
    $1

    Usage:
      $1 [-p <port>] [--appname <appName>] [--local]

    Options:
      -h --help           Show this screen.
      --version           Show version.
      -p --port <port>    Http server port [default: $2]
      --appname <appName> Set appName.
      --local             Use local public dir.
  """ % [AppName, $DefaultPort]
  let args = doc.dedent.docopt(version = Version)

  result.port = try: parseInt($args["--port"]) except: DefaultPort
  if args["--appname"]:
    result.appName = "/" & $args["--appname"]

  useLocalDir = args["--local"].to_bool

when isMainModule:
  let cmdOpt = readCmdOpt()
  randomize()
  createTables()
  startWebServer(cmdOpt.port, cmdOpt.appName)
