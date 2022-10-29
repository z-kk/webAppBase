import
  db_sqlite,
  std / os,
  csvDir / [authUserInfo]
export
  db_sqlite,
  authUserInfo
proc getDbFileName*(): string =
  getConfigDir() / getAppFilename().extractFilename / "webapp.db"
proc openDb*(): DbConn =
  let db = open(getDbFileName(), "", "", "")
  return db
proc createTables*(db: DbConn) =
  db.createAuthUserInfoTable
