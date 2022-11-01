import unittest

import
  std / [os, strutils, osproc, json],
  std / [httpcore, httpclient],
  webAppBasepkg / [auth, dbtables]

const
  BinDir = "bin"
  AppName = "webAppBase"
  Host = "http://localhost:5000/" & AppName & "/"

test "build app":
  let nimblePath = getHomeDir() / ".nimble/bin/nimble"
  discard execProcess(nimblePath & " build")

  # dirを移動
  setCurrentDir(BinDir)

# start jester server
let p = startProcess("." / AppName)

test "make symlink":
  let targetDbFile = getConfigDir() / AppName / getDbFileName().extractFilename
  getDbFileName().removeFile
  targetDbFile.createSymlink(getDbFileName())

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

  let h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])

  # not login session
  res = c.request(Host & "userconf")
  check res.body.contains("login.js")

  # use login session
  res = c.request(Host & "userconf", headers = h)
  check not res.body.contains("login.js")

test "get auth users":
  let muser = "master_user"
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

test "http userconf page":
  let c = newHttpClient()
  # post login data
  var data = newMultipartData({"userid": tuser, "passwd": tpass})
  var res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  # get userconf page
  var h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])
  res = c.request(Host & "userconf", headers = h)
  check res.body.contains("userlistfrm")

  # get userconf page by guest
  let guser = "guest_user"
  check addNewUser(guser, tpass)["result"].getBool

  data = newMultipartData({"userid": guser, "passwd": tpass})
  res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool
  h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])
  res = c.request(Host & "userconf", headers = h)
  check not res.body.contains("userlistfrm")

  db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, guser)

test "http userconf api":
  let c = newHttpClient()
  # post login data
  var data = newMultipartData({"userid": tuser, "passwd": tpass})
  var res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  let muser = "member_user"
  check addNewUser(muser, tpass)["result"].getBool

  data = newMultipartData({muser & "_prm": $pmMember.ord, muser & "_enb": "false"})
  res = c.request(Host & "userconf", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, muser)

test "change password":
  let puser = "pass_user"
  check addNewUser(puser, tpass)["result"].getBool

  let newpass = "new_pass"
  check not changeUserPass(puser, newpass, newpass)["result"].getBool
  check changeUserPass(puser, tpass, newpass)["result"].getBool

  check login(puser, newpass)["result"].getBool

  db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, puser)

test "http changepass api":
  let c = newHttpClient()
  let puser = "pass_user"
  check addNewUser(puser, tpass)["result"].getBool

  # post login data
  var data = newMultipartData({"userid": puser, "passwd": tpass})
  var res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  let h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])

  let newpass = "new_pass"
  data = newMultipartData({"userid": puser, "oldpasswd": tpass, "passwd": newpass})
  res = c.request(Host & "changepw", HttpPost, headers = h, multipart = data)
  check res.body.parseJson["result"].getBool

  # post login data
  data = newMultipartData({"userid": puser, "passwd": newpass})
  res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, puser)

db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, tuser)
db.close
p.kill
