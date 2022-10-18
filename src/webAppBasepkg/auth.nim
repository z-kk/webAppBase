import
  std / [tables, times],
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

var sessions {.threadvar.}: Table[int, SessionInfo]

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
    break
