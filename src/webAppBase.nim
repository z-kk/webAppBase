import
  std / [os, strutils, random],
  webAppBasepkg / [webserver, dbtables]

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

proc getPort(): int =
  if commandLineParams().len == 0:
    DefaultPort
  else:
    try:
      commandLineParams()[0].parseInt
    except:
      quit("usage: $1 [Port]" % [appName])

when isMainModule:
  randomize()
  createDb()
  startWebServer(getPort(), "/" & appName)
