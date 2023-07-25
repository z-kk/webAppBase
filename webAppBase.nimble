# Package

version       = "0.1.3"
author        = "z-kk"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["webAppBase"]
binDir        = "bin"


# Dependencies

requires "nim >= 1.6.0"
requires "jester >= 0.5.0"
requires "libsha >= 1.0"
requires "htmlgenerator >= 0.1.7"
requires "docopt >= 0.7.0"


# Tasks

import std / [os, strutils]
task r, "make link and run":
  exec "nimble build"
  withDir binDir:
    let staticDir = "public"
    if not staticDir.dirExists:
      exec "ln -s " & ".." / srcDir / "html " & staticDir
    exec "." / bin[0]

task inst, "install":
  let staticDir = getConfigDir() / bin[0] / "public"
  staticDir.parentDir.mkDir
  staticDir.rmDir
  cpDir(srcDir / "html", staticDir)
  exec "nimble install"

task release, "build release bin":
  binDir.rmDir
  exec "nimble -d:release build"
  withDir binDir:
    let staticDir = "public"
    staticDir.rmDir
    cpDir(".." / srcDir / "html", staticDir)
    "README.txt".writeFile("copy public dir to ~/.config/$1/$2\n" % [bin[0], staticDir])


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
