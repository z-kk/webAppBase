import
  std / [os, strutils, random],
  webAppBasepkg / [webserver, dbtables]

const
  DefaultPort = 5000

proc createConfDir() =
  let dir = getConfigDir() / getAppFilename().extractFilename
  dir.createDir

proc createDb() =
  if not getDbFileName().fileExists:
    createConfDir()
    let db = openDb()
    db.createTables

proc getPort(): int =
  if commandLineParams().len == 0:
    DefaultPort
  else:
    try:
      commandLineParams()[0].parseInt
    except:
      echo "usage: $1 [Port]" % [getAppFilename().extractFilename]
      quit()

when isMainModule:
  randomize()
  createDb()
  startWebServer(getPort())
