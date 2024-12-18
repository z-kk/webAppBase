import
  std / [os, strutils, sequtils, times, parsecsv],
  db_connector / db_sqlite

type
  AuthUserInfoCol* {.pure.} = enum
    id, login_id, permission, passwd, created_at, updated_at, deleted_at
  AuthUserInfoTable* = object
    primKey: int
    id*: int
    login_id*: string
    permission*: int
    passwd*: string
    created_at*: DateTime
    updated_at*: DateTime
    deleted_at*: DateTime

proc setDataAuthUserInfoTable*(data: var AuthUserInfoTable, colName, value: string) =
  case colName
  of "id":
    try:
      data.id = value.parseInt
    except: discard
  of "login_id":
    try:
      data.login_id = value
    except: discard
  of "permission":
    try:
      data.permission = value.parseInt
    except: discard
  of "passwd":
    try:
      data.passwd = value
    except: discard
  of "created_at":
    try:
      data.created_at = value.parse("yyyy-MM-dd HH:mm:ss")
    except: discard
  of "updated_at":
    try:
      data.updated_at = value.parse("yyyy-MM-dd HH:mm:ss")
    except: discard
  of "deleted_at":
    try:
      data.deleted_at = value.parse("yyyy-MM-dd HH:mm:ss")
    except: discard

proc createAuthUserInfoTable*(db: DbConn) =
  let sql = """
    create table if not exists authUserInfo(
      id INTEGER not null primary key,
      login_id TEXT not null,
      permission INTEGER default 1 not null,
      passwd TEXT not null,
      created_at DATETIME default '9999-12-31' not null,
      updated_at DATETIME default '9999-12-31' not null,
      deleted_at DATETIME default '9999-12-31' not null
    )
  """.sql
  db.exec(sql)

proc tryInsertAuthUserInfoTable*(db: DbConn, rowData: AuthUserInfoTable): int64 =
  var vals: seq[string]
  var sql = "insert into authUserInfo("
  if rowData.id > 0:
    sql.add "id,"
    vals.add $rowData.id
  sql.add "login_id,"
  vals.add rowData.login_id
  sql.add "permission,"
  vals.add $rowData.permission
  sql.add "passwd,"
  vals.add rowData.passwd
  if rowData.created_at != DateTime():
    sql.add "created_at,"
    vals.add rowData.created_at.format("yyyy-MM-dd HH:mm:ss")
  if rowData.updated_at != DateTime():
    sql.add "updated_at,"
    vals.add rowData.updated_at.format("yyyy-MM-dd HH:mm:ss")
  if rowData.deleted_at != DateTime():
    sql.add "deleted_at,"
    vals.add rowData.deleted_at.format("yyyy-MM-dd HH:mm:ss")
  sql[^1] = ')'
  sql.add " values ("
  sql.add sequtils.repeat("?", vals.len).join(",")
  sql.add ')'
  return db.tryInsertID(sql.sql, vals)
proc insertAuthUserInfoTable*(db: DbConn, rowData: AuthUserInfoTable) =
  let res = tryInsertAuthUserInfoTable(db, rowData)
  if res < 0: db.dbError
proc insertAuthUserInfoTable*(db: DbConn, rowDataList: seq[AuthUserInfoTable]) =
  for rowData in rowDataList:
    db.insertAuthUserInfoTable(rowData)

proc selectAuthUserInfoTable*(db: DbConn, whereStr = "", orderBy: seq[string], whereVals: varargs[string, `$`]): seq[AuthUserInfoTable] =
  var sql = "select * from authUserInfo"
  if whereStr != "":
    sql.add " where " & whereStr
  if orderBy.len > 0:
    sql.add " order by " & orderBy.join(",")
  let rows = db.getAllRows(sql.sql, whereVals)
  for row in rows:
    var res: AuthUserInfoTable
    res.primKey = row[AuthUserInfoCol.id.ord].parseInt
    res.setDataAuthUserInfoTable("id", row[AuthUserInfoCol.id.ord])
    res.setDataAuthUserInfoTable("login_id", row[AuthUserInfoCol.login_id.ord])
    res.setDataAuthUserInfoTable("permission", row[AuthUserInfoCol.permission.ord])
    res.setDataAuthUserInfoTable("passwd", row[AuthUserInfoCol.passwd.ord])
    res.setDataAuthUserInfoTable("created_at", row[AuthUserInfoCol.created_at.ord])
    res.setDataAuthUserInfoTable("updated_at", row[AuthUserInfoCol.updated_at.ord])
    res.setDataAuthUserInfoTable("deleted_at", row[AuthUserInfoCol.deleted_at.ord])
    result.add res
proc selectAuthUserInfoTable*(db: DbConn, whereStr = "", whereVals: varargs[string, `$`]): seq[AuthUserInfoTable] =
  selectAuthUserInfoTable(db, whereStr, @[], whereVals)

proc updateAuthUserInfoTable*(db: DbConn, rowData: AuthUserInfoTable) =
  if rowData.primKey < 1:
    return
  var
    vals: seq[string]
    sql = "update authUserInfo set "
  sql.add "login_id = ?,"
  vals.add rowData.login_id
  sql.add "permission = ?,"
  vals.add $rowData.permission
  sql.add "passwd = ?,"
  vals.add rowData.passwd
  if rowData.created_at != DateTime():
    sql.add "created_at = ?,"
    vals.add rowData.created_at.format("yyyy-MM-dd HH:mm:ss")
  if rowData.updated_at != DateTime():
    sql.add "updated_at = ?,"
    vals.add rowData.updated_at.format("yyyy-MM-dd HH:mm:ss")
  if rowData.deleted_at != DateTime():
    sql.add "deleted_at = ?,"
    vals.add rowData.deleted_at.format("yyyy-MM-dd HH:mm:ss")
  sql[^1] = ' '
  sql.add "where id = " & $rowData.primKey
  db.exec(sql.sql, vals)
proc updateAuthUserInfoTable*(db: DbConn, rowDataList: seq[AuthUserInfoTable]) =
  for rowData in rowDataList:
    db.updateAuthUserInfoTable(rowData)

proc dumpAuthUserInfoTable*(db: DbConn, dirName = ".") =
  dirName.createDir
  let
    fileName = dirName / "authUserInfo.csv"
    f = fileName.open(fmWrite)
  f.writeLine "id,login_id,permission,passwd,created_at,updated_at,deleted_at"
  for row in db.selectAuthUserInfoTable:
    f.write "\"$#\"," % [$row.id]
    f.write "\"$#\"," % [$row.login_id]
    f.write "\"$#\"," % [$row.permission]
    f.write "\"$#\"," % [$row.passwd]
    if row.created_at == DateTime():
      f.write ","
    else:
      f.write row.created_at.format("yyyy-MM-dd HH:mm:ss"), ","
    if row.updated_at == DateTime():
      f.write ","
    else:
      f.write row.updated_at.format("yyyy-MM-dd HH:mm:ss"), ","
    if row.deleted_at == DateTime():
      f.write ","
    else:
      f.write row.deleted_at.format("yyyy-MM-dd HH:mm:ss"), ","
    f.setFilePos(f.getFilePos - 1)
    f.writeLine ""
  f.close

proc insertCsvAuthUserInfoTable*(db: DbConn, fileName: string) =
  var parser: CsvParser
  defer: parser.close
  parser.open(fileName)
  parser.readHeaderRow
  while parser.readRow:
    var data: AuthUserInfoTable
    data.setDataAuthUserInfoTable("id", parser.rowEntry("id"))
    data.setDataAuthUserInfoTable("login_id", parser.rowEntry("login_id"))
    data.setDataAuthUserInfoTable("permission", parser.rowEntry("permission"))
    data.setDataAuthUserInfoTable("passwd", parser.rowEntry("passwd"))
    data.setDataAuthUserInfoTable("created_at", parser.rowEntry("created_at"))
    data.setDataAuthUserInfoTable("updated_at", parser.rowEntry("updated_at"))
    data.setDataAuthUserInfoTable("deleted_at", parser.rowEntry("deleted_at"))
    db.insertAuthUserInfoTable(data)

proc restoreAuthUserInfoTable*(db: DbConn, dirName = ".") =
  let fileName = dirName / "authUserInfo.csv"
  db.exec("delete from authUserInfo".sql)
  db.insertCsvAuthUserInfoTable(fileName)
