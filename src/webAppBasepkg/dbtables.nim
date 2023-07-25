import
  std / os,
  db_connector / db_sqlite,
  csvDir / [authUserInfo]
export
  db_sqlite,
  authUserInfo
proc getDbFileName*(): string =
  let dir = getDataDir() / getAppFilename().extractFilename
  return dir / "webapp.db"
proc openDb*(): DbConn =
  let db = open(getDbFileName(), "", "", "")
  return db
proc createTables*() =
  getDbFileName().parentDir.createDir
  let db = openDb()
  db.createAuthUserInfoTable
  db.close
