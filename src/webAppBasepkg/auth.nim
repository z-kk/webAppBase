import
  std / [strutils, tables, times, json, random],
  libsha / sha256,
  dbtables

type
  Permission* = enum
    pmNone,
    pmGuest,
    pmMember,
    pmMaster,
    pmOwner

  LoginUser* = object
    id*: string
    permission*: Permission
    isEnable*: bool

  SessionInfo = object
    userId: int
    expiration: DateTime

const
  expirationDuration = initDuration(days = 7)

var sessions {.threadvar.}: Table[int, SessionInfo]

proc makeSession(id: int): int =
  ## Make new session with user id.
  result = rand(0xffff)

  var s: SessionInfo
  s.userId = id
  s.expiration = now() + expirationDuration
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

  let rows = db.selectAuthUserInfoTable("id = " & $session.userId)
  for row in rows:
    result.id = row.login_id
    result.permission = Permission(row.permission)
    result.isEnable = row.deleted_at > nw
    sessions[id].expiration = nw + expirationDuration
    break

proc addNewUser*(id, pass: string): JsonNode =
  ## Insert new user into auth user table.
  result = %*{"result": false, "err": "unknown error!"}

  let db = openDb()
  defer: db.close

  if db.selectAuthUserInfoTable("login_id = '$1'" % [id]).len > 0:
    result["err"] = %("user $1 is already exists!" % [id])
    return

  var u: AuthUserInfoTable
  let nw = now()
  u.login_id = id
  u.permission = pmGuest.ord
  u.passwd = pass.sha256hexdigest
  u.created_at = nw
  u.updated_at = nw
  u.deleted_at = "9999-12-31".parse("yyyy-MM-dd")

  try:
    db.insertAuthUserInfoTable(u)
  except:
    result["err"] = %"insert error"
    return

  u = db.selectAuthUserInfoTable("login_id = '$1'" % [id])[0]

  result["id"] = %u.id.makeSession
  result["result"] = %true
  result.delete("err")

proc login*(id, pass: string): JsonNode =
  ## Check login user info.
  result = %*{"result": false, "err": "unknown error!"}

  let db = openDb()
  defer:db.close

  # search user in db table
  let rows = db.selectAuthUserInfoTable("login_id = '$1'" % [id])
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
        sessions[key].expiration = nw + expirationDuration
    # make session
    if resid < 0:
      resid = makeSession(row.id)

    result["id"] = %resid
    result["result"] = %true
    result.delete("err")
    break
