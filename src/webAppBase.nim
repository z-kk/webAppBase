import
  std / [os, strutils, parseopt, random],
  webAppBasepkg / [webserver, dbtables]

type
  CmdOpt = object
    port: int

const
  DefaultPort = 5000

let
  appName = getAppFilename().extractFilename

proc createConfDir() =
  let dir = getConfigDir() / appName
  dir.createDir

proc createDb() =
  if not getDbFileName().fileExists:
    createConfDir()
    let db = openDb()
    defer: db.close
    db.createTables

proc readCmdOpt(): CmdOpt =
  ## Read command line options.
  var
    p = initOptParser()
    fail = false
  while true:
    p.next
    case p.kind
    of cmdArgument:
      if result.port == 0:
        try:
          result.port = p.key.parseInt
        except:
          fail = true
          break
      else:
        fail = true
        break
    of cmdLongOption, cmdShortOption:
      case p.key
      of "p", "port":
        var val = p.val
        if val == "":
          p.next
          if p.kind != cmdArgument:
            fail = true
            break
          val = p.key
        try:
          result.port = val.parseInt
        except:
          fail = true
          break
      else:
        fail = true
        break
    of cmdEnd:
      break

  if fail:
    quit("usage: $1 [[-p|--port] Port]" % [appName])

  if result.port == 0:
    result.port = DefaultPort

when isMainModule:
  randomize()
  createDb()
  let cmdOpt = readCmdOpt()
  startWebServer(cmdOpt.port, "/" & appName)
