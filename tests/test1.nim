import unittest

import
  std / [os, strutils, osproc, json],
  std / [httpcore, httpclient],
  webAppBasepkg / [auth, dbtables]

const
  BinDir = "bin"
  AppName = "webAppBase"
  Host = "http://localhost:5000/"

test "build app":
  let nimblePath = getHomeDir() / ".nimble/bin/nimble"
  discard execProcess(nimblePath & " build")

  # dirを移動
  setCurrentDir(BinDir)

# start jester server
let p = startProcess("." / AppName)
let db = openDb()
let tuser = "test_user"
let tpass = "test_pass"

test "make test user":
  check addNewUser(tuser, tpass)["result"].getBool

  var user = db.selectAuthUserInfoTable("login_id = '$1'" % [tuser])[0]
  user.permission = pmOwner.ord
  db.updateAuthUserInfoTable(user)

test "test login api":
  let loginRes = login(tuser, tpass)
  check loginRes["result"].getBool

test "http newuser request":
  let c = newHttpClient()
  # post newuser data
  let data = newMultipartData({"userid": tuser, "passwd": ""})
  let res = c.request(Host & "newuser", HttpPost, multipart = data)
  check not res.body.parseJson["result"].getBool
  check res.body.parseJson["err"].getStr.contains("already exists")

test "http login sessoin":
  let c = newHttpClient()
  # post login data
  let data = newMultipartData({"userid": tuser, "passwd": tpass})
  var res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  # use login session
  var h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])
  res = c.request(Host & "userconf", headers = h)
  check not res.body.contains("login.js")

test "get auth users":
  var muser = "master_user"
  var res = false
  for user in pmOwner.getAuthUsers:
    if user.id == tuser:
      res = user.isEnable

  if not res:
    echo "test user not exist!"
    check res

  check addNewUser(muser, tpass)["result"].getBool
  var u = db.selectAuthUserInfoTable("login_id = '$1'" % [muser])[0]
  u.permission = pmMaster.ord
  db.updateAuthUserInfoTable(u)

  res = false
  for user in pmMaster.getAuthUsers:
    if user.id == muser:
      res = user.isEnable
    check user.id != tuser

  if not res:
    echo "master user not exist!"
    check res

  db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, muser)

db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, tuser)
db.close
p.kill
