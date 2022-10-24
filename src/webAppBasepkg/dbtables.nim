import
  db_sqlite,
  csvDir / [authUserInfo]
export
  db_sqlite,
  authUserInfo
const
  DbFileName* = "webapp.db"
proc openDb*(): DbConn =
  let db = open(DbFileName, "", "", "")
  return db
proc createTables*(db: DbConn) =
  db.createAuthUserInfoTable
