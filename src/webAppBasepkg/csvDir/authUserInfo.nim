import
  os, strutils, strformat, parsecsv,
  times,
  db_sqlite
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
  let sql = """create table if not exists authUserInfo(
    id INTEGER not null primary key,
    login_id TEXT not null,
    permission INTEGER default 1 not null,
    passwd TEXT not null,
    created_at DATETIME default '9999-12-31' not null,
    updated_at DATETIME default '9999-12-31' not null,
    deleted_at DATETIME default '9999-12-31' not null
  )""".sql
  db.exec(sql)
proc insertAuthUserInfoTable*(db: DbConn, rowData: AuthUserInfoTable) =
  var sql = "insert into authUserInfo("
  if rowData.id > 0:
    sql &= "id,"
  sql &= """login_id,permission,passwd,created_at,updated_at,deleted_at
    ) values ("""
  if rowData.id > 0:
    sql &= &"{rowData.id},"
  sql &= &"'{rowData.login_id}',{rowData.permission},'{rowData.passwd}',datetime('" & rowData.created_at.format("yyyy-MM-dd HH:mm:ss") & &"'),datetime('" & rowData.updated_at.format("yyyy-MM-dd HH:mm:ss") & &"'),datetime('" & rowData.deleted_at.format("yyyy-MM-dd HH:mm:ss") & &"')"
  sql &= ")"
  db.exec(sql.sql)
proc insertAuthUserInfoTable*(db: DbConn, rowDataSeq: seq[AuthUserInfoTable]) =
  for rowData in rowDataSeq:
    db.insertAuthUserInfoTable(rowData)
proc selectAuthUserInfoTable*(db: DbConn, whereStr = "", orderStr = ""): seq[AuthUserInfoTable] =
  var sql = "select * from authUserInfo"
  if whereStr != "":
    sql &= " where " & whereStr
  if orderStr != "":
    sql &= " order by " & orderStr
  let rows = db.getAllRows(sql.sql)
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
    result.add(res)
proc updateAuthUserInfoTable*(db: DbConn, rowData: AuthUserInfoTable) =
  if rowData.primKey < 1: return
  var sql = "update authUserInfo set "
  sql &= &" login_id = '{rowData.login_id}'"
  sql &= &",permission = {rowData.permission}"
  sql &= &",passwd = '{rowData.passwd}'"
  if rowData.created_at != DateTime():
    sql &= &",created_at = datetime('" & rowData.created_at.format("yyyy-MM-dd HH:mm:ss") & &"')"
  if rowData.updated_at != DateTime():
    sql &= &",updated_at = datetime('" & rowData.updated_at.format("yyyy-MM-dd HH:mm:ss") & &"')"
  if rowData.deleted_at != DateTime():
    sql &= &",deleted_at = datetime('" & rowData.deleted_at.format("yyyy-MM-dd HH:mm:ss") & &"')"

  sql &= &" where id = {rowData.primKey}"
  db.exec(sql.sql)
proc updateAuthUserInfoTable*(db: DbConn, rowDataSeq: seq[AuthUserInfoTable]) =
  for rowData in rowDataSeq:
    db.updateAuthUserInfoTable(rowData)
proc dumpAuthUserInfoTable*(db: DbConn, dirName = "csv") =
  dirName.createDir
  let
    fileName = dirName / "authUserInfo.csv"
    f = fileName.open(fmWrite)
  f.writeLine("id,login_id,permission,passwd,created_at,updated_at,deleted_at")
  for row in db.selectAuthUserInfoTable:
    f.write('"', $row.id, '"', ',')
    f.write('"', $row.login_id, '"', ',')
    f.write('"', $row.permission, '"', ',')
    f.write('"', $row.passwd, '"', ',')
    if row.created_at == DateTime():
      f.write(',')
    else:
      f.write(row.created_at.format("yyyy-MM-dd HH:mm:ss"), ',')
    if row.updated_at == DateTime():
      f.write(',')
    else:
      f.write(row.updated_at.format("yyyy-MM-dd HH:mm:ss"), ',')
    if row.deleted_at == DateTime():
      f.write(',')
    else:
      f.write(row.deleted_at.format("yyyy-MM-dd HH:mm:ss"), ',')
    f.setFilePos(f.getFilePos - 1)
    f.writeLine("")
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
proc restoreAuthUserInfoTable*(db: DbConn, dirName = "csv") =
  let fileName = dirName / "authUserInfo.csv"
  db.exec("delete from authUserInfo".sql)
  db.insertCsvAuthUserInfoTable(fileName)
