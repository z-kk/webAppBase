import
  std / [strutils, tables, times, json, rdstdin, terminal, random],
  libsha / sha256,
  utils, dbtables

type
  Permission* = enum
    pmNone = "None"
    pmGuest = "Guest"
    pmMember = "Member"
    pmMaster = "Master"
    pmOwner = "Owner"

  LoginUser* = object
    id*: string
    permission*: Permission
    isEnable*: bool

  SessionInfo = object
    userId: int
    expiration: DateTime

const
  ExpirationDuration = initDuration(days = 7)

var sessions {.threadvar.}: Table[int, SessionInfo]

proc maxDate(): DateTime =
  "9999-12-31".parse("yyyy-MM-dd")

proc makeSession(id: int): int =
  ## Make new session with user id.
  while result == 0 or result in sessions:
    result = rand(0xffff)

  var s: SessionInfo
  s.userId = id
  s.expiration = now() + ExpirationDuration
  sessions[result] = s

proc getSessionUser*(id: int): LoginUser =
  ## Get login user by session id.
  if not id in sessions:
    return

  let
    session = sessions[id]
    nw = now()
  if session.expiration < nw:
    # delete expired data
    for key in sessions.keys:
      if sessions[key].expiration < nw:
        sessions.del(key)
    return

  let db = openDb()
  defer: db.close

  let rows = db.selectAuthUserInfoTable("id = ?", @[], session.userId)
  for row in rows:
    result.id = row.login_id
    result.permission = Permission(row.permission)
    result.isEnable = row.deleted_at > nw
    sessions[id].expiration = nw + ExpirationDuration
    break

proc addNewUser*(id, pass: string): JsonNode =
  ## Insert new user into auth user table.
  result = newResult()

  let db = openDb()
  defer: db.close

  if db.selectAuthUserInfoTable("login_id = ?", @[], id).len > 0:
    result["err"] = %("user $1 is already exists!" % [id])
    return

  var u: AuthUserInfoTable
  let nw = now()
  u.login_id = id
  u.permission = pmGuest.ord
  u.passwd = pass.sha256hexdigest
  u.created_at = nw
  u.updated_at = nw
  u.deleted_at = maxDate()

  try:
    db.insertAuthUserInfoTable(u)
  except:
    result["err"] = %"insert error"
    return

  u = db.selectAuthUserInfoTable("login_id = ?", @[], id)[0]

  result["id"] = %u.id.makeSession
  result.success

proc changeUserPass*(id, old, pass: string): JsonNode =
  ## Change users password.
  result = newResult()

  let db = openDb()
  defer: db.close

  # search user in db table
  let rows = db.selectAuthUserInfoTable("login_id = ?", @[], id)
  if rows.len == 0:
    result["err"] = %"no such user"
    return

  for row in rows:
    var user = row
    if old.sha256hexdigest != user.passwd:
      result["err"] = %"wrong old password"
      return

    user.passwd = pass.sha256hexdigest
    user.updated_at = now()
    db.updateAuthUserInfoTable(user)

    result.success
    break

proc login*(id, pass: string): JsonNode =
  ## Check login user info.
  result = newResult()

  let db = openDb()
  defer:db.close

  # search user in db table
  let rows = db.selectAuthUserInfoTable("login_id = ?", @[], id)
  if rows.len == 0:
    result["err"] = %"no such user"
    return

  for row in rows:
    var resid = -1
    # check password
    if row.passwd != pass.sha256hexdigest:
      result["err"] = %"could not login"
      return
    let nw = now()
    # check deleted or not
    if row.deleted_at < nw:
      result["err"] = %"this user has been deleted"
      return
    # search exists session
    for key in sessions.keys:
      if sessions[key].userId == row.id:
        resid = key
        sessions[key].expiration = nw + ExpirationDuration
    # make session
    if resid < 0:
      resid = makeSession(row.id)

    result["id"] = %resid
    result.success
    break

proc getAuthUsers*(pm: Permission): seq[LoginUser] =
  ## Get auth users info list.
  let db = openDb()
  defer: db.close

  var perms: seq[int]
  for i in Permission.low.ord .. pm.ord:
    perms.add i
  let rows = db.selectAuthUserInfoTable("permission in ($1)" % [perms.join(",")])
  for row in rows:
    var user: LoginUser
    user.id = row.login_id
    user.permission = Permission(row.permission)
    user.isEnable = row.deleted_at > now()
    result.add user

proc updateAuthUsers*(users: seq[LoginUser]): JsonNode =
  ## Update auth users info.
  result = newResult()

  let db = openDb()
  defer: db.close

  var loginIdList = @[""]
  for user in users:
    loginIdList.add user.id

  let data = db.selectAuthUserInfoTable("login_id in ($1)" % ["?,".repeat(loginIdList.len)[0..^2]], @[], loginIdList)
  var dataTable = newTable[string, AuthUserInfoTable]()
  for user in data:
    dataTable[user.login_id] = user

  var targets: seq[AuthUserInfoTable]
  let nw = now()
  for user in users:
    var tgt = dataTable[user.id]
    tgt.permission = user.permission.ord
    tgt.updated_at = nw
    if user.isEnable:
      tgt.deleted_at = maxDate()
    elif tgt.deleted_at > nw:
      tgt.deleted_at = nw
    targets.add tgt

  try:
    db.updateAuthUserInfoTable(targets)
    result.success
  except:
    return

proc createOwnerUser*(): bool =
  ## Create owner user.
  echo "管理者ユーザーを作成"
  let
    userName = readLineFromStdin("ユーザー名: ")
    userPass = readPasswordFromStdin()
  var
    res = addNewUser(userName, userPass)
  if not res["result"].getBool:
    echo res["err"].getStr
    return false

  var
    user = LoginUser(id: userName, permission: pmOwner, isEnable: true)
  res = updateAuthUsers(@[user])
  if not res["result"].getBool:
    echo res["err"].getStr
    return false

  return true
