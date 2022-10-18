import
  std / os,
  webAppBasepkg / [webserver, dbtables]

proc createDb() =
  if not DbFileName.fileExists:
    let db = openDb()
    db.createTables

when isMainModule:
  createDb()
  startWebServer()
