import
  std / [os, random],
  webAppBasepkg / [webserver, dbtables]

proc createConfDir() =
  let dir = getConfigDir() / getAppFilename().extractFilename
  dir.createDir

proc createDb() =
  if not getDbFileName().fileExists:
    createConfDir()
    let db = openDb()
    db.createTables

when isMainModule:
  randomize()
  createDb()
  startWebServer()
