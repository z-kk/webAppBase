import
  std / [strutils, random],
  docopt,
  webAppBasepkg / [webserver, dbtables, nimbleInfo]

when defined(release):
  import
    std / [os]

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
      $1 [-p <port>] [(-n [<appName>])]

    Options:
      -h --help         Show this screen.
      --version         Show version.
      -p --port <port>  Http server port [default: $2]
      -n --name         Use appName
      <appName>         Set appName
  """ % [AppName, $DefaultPort]
  let args = doc.dedent.docopt(version = Version)

  result.port = try: parseInt($args["--port"]) except: DefaultPort
  if args["--name"]:
    result.appName = "/"
    if args["<appName>"].kind == vkNone:
      result.appName.add AppName
    else:
      result.appName.add $args["<appName>"]

when isMainModule:
  randomize()
  createTables()
  let
    cmdOpt = readCmdOpt()
    staticDir =
      when defined(release):
        getConfigDir() / AppName / "public"
      else:
        ""
  startWebServer(cmdOpt.port, staticDir, cmdOpt.appName)
