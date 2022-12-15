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
  let staticDir = getConfigDir() / bin[0] / "public"
  staticDir.parentDir.mkDir
  if not staticDir.dirExists:
    exec "ln -s " & getCurrentDir() / srcDir / "html " & staticDir
  exec "nimble -d:Version=v$1 run" % [version]

task inst, "install":
  let staticDir = getConfigDir() / bin[0] / "public"
  staticDir.parentDir.mkDir
  staticDir.rmDir
  cpDir(srcDir / "html", staticDir)
  let confFile = srcDir / "$1.nim.cfg" % [bin[0]]
  writeFile(confFile, "-d:Version=\"v$1\"\n" % [version])
  exec "nimble install"
  confFile.rmFile

task release, "build release bin":
  exec "nimble -d:release -d:Version=v$1 build" % [version]
  withDir binDir:
    let staticDir = "public"
    staticDir.rmDir
    cpDir(".." / srcDir / "html", staticDir)
    "README.txt".writeFile("copy public dir to ~/.config/$1/$2\n" % [bin[0], staticDir])
