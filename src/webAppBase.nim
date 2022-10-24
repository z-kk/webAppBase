import
  std / [os, random],
  webAppBasepkg / [webserver, dbtables]

proc createDb() =
  if not DbFileName.fileExists:
    let db = openDb()
    db.createTables

when isMainModule:
  randomize()
  createDb()
  startWebServer()
