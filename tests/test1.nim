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
var userid: string
let testPass = "test_pass"

test "make test user":
  let pref = "test_user"
  var suf = 1
  while not addNewUser(pref & $suf, testPass)["result"].getBool:
    suf.inc
  userid = pref & $suf

test "test login api":
  let loginRes = login(userid, testPass)
  check loginRes["result"].getBool

test "http newuser request":
  let c = newHttpClient()
  # post newuser data
  let data = newMultipartData({"userid": userid, "passwd": ""})
  let res = c.request(Host & "newuser", HttpPost, multipart = data)
  check not res.body.parseJson["result"].getBool
  check res.body.parseJson["err"].getStr.contains("already exists")

test "http login sessoin":
  let c = newHttpClient()
  # post login data
  let data = newMultipartData({"userid": userid, "passwd": testPass})
  var res = c.request(Host & "login", HttpPost, multipart = data)
  check res.body.parseJson["result"].getBool

  # use login session
  var h = newHttpHeaders(@[("cookie", $res.headers["set-cookie"])])
  res = c.request(Host & "userconf", headers = h)
  check not res.body.contains("login.js")

db.exec("DELETE FROM authUserInfo WHERE login_id = ?".sql, userid)
db.close
p.kill
