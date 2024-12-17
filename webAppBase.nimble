# Package

version       = "0.2.0"
author        = "z-kk"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["webAppBase"]
binDir        = "bin"


# Dependencies

requires "nim >= 2.0.0"
requires "db_connector"
requires "jester >= 0.6.0"
requires "libsha >= 1.0"
requires "htmlgenerator >= 0.1.7"
requires "docopt >= 0.7.1"


# Tasks

import std / [os, strutils]
task r, "build and run":
  exec "nimble build"
  withDir binDir:
    let staticDir = "public"
    if not staticDir.dirExists:
      exec "ln -s $1 $2" % [".." / srcDir / "html ", staticDir]
  exec "nimble ex"

task ex, "run without build":
  withDir binDir:
    exec "." / bin[0]

task release, "build release bin":
  binDir.rmDir
  exec "nimble -d:release build"
  withDir binDir:
    let staticDir = "public"
    cpDir(".." / srcDir / "html", staticDir)
    "README.txt".writeFile("copy $2 dir to ~/.config/$1/$2\n" % [bin[0], staticDir])


# Before / After

before build:
  let infoFile = srcDir / bin[0] & "pkg" / "nimbleInfo.nim"
  infoFile.parentDir.mkDir
  infoFile.writeFile("""
    const
      AppName* = "$#"
      Version* = "$#"
  """.dedent % [bin[0], version])

after build:
  let infoFile = srcDir / bin[0] & "pkg" / "nimbleInfo.nim"
  infoFile.writeFile("""
    const
      AppName* = ""
      Version* = ""
  """.dedent)

before install:
  let staticDir = getConfigDir() / bin[0] / "public"
  staticDir.parentDir.mkDir
  staticDir.rmDir
  cpDir(srcDir / "html", staticDir)
