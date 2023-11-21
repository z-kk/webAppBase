import
  std / os,
  db_connector / db_sqlite,
  csvDir / [authUserInfo]
when defined(release):
  import
    submodule, nimbleInfo
export
  db_sqlite,
  authUserInfo
proc getDbFileName*(): string =
  let dir =
    when defined(release):
      if useLocalDir:
        "."
      else:
        getDataDir() / AppName
    else:
      "."
  return dir / "webapp.db"
proc openDb*(): DbConn =
  let db = open(getDbFileName(), "", "", "")
  return db
proc createTables*() =
  getDbFileName().parentDir.createDir
  let db = openDb()
  db.createAuthUserInfoTable
  db.close
