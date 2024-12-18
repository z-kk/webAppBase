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

proc openDb*(fileName = getDbFileName()): DbConn =
  return open(fileName, "", "", "")

proc createTables*(fileName = getDbFileName()) =
  fileName.parentDir.createDir
  let db = fileName.openDb
  db.createAuthUserInfoTable
  db.close
