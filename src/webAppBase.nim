import
  std / [os, strutils, random],
  docopt,
  webAppBasepkg / [webserver, dbtables]

type
  CmdOpt = object
    port: int
    appName: string

const
  Version {.strdefine.} = ""
  DefaultPort = 5000

let
  appName = getAppFilename().extractFilename

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
  """ % [appName, $DefaultPort]
  let args = doc.dedent.docopt(version = Version)

  result.port = try: parseInt($args["--port"]) except: DefaultPort
  if args["--name"]:
    result.appName = "/"
    if args["<appName>"].kind == vkNone:
      result.appName.add appName
    else:
      result.appName.add $args["<appName>"]

proc createConfDir() =
  let dir = getConfigDir() / appName
  dir.createDir

proc createDb() =
  if not getDbFileName().fileExists:
    createConfDir()
    let db = openDb()
    defer: db.close
    db.createTables

when isMainModule:
  randomize()
  createDb()
  let cmdOpt = readCmdOpt()
  startWebServer(cmdOpt.port, cmdOpt.appName)
