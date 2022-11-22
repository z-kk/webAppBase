# Package

version       = "0.1.2"
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
requires "htmlgenerator >= 0.1.6"
requires "docopt >= 0.7.0"


# Tasks

import std / [os, strutils]
task r, "make link and run":
  let publicFilePath = getConfigDir() / bin[0] / "public"
  if not publicFilePath.parentDir.dirExists:
    exec "mkdir $1" % [publicFilePath.parentDir]
  if not publicFilePath.dirExists:
    exec "ln -s " & getCurrentDir() / srcDir / "html " & publicFilePath
  exec "nimble -d:Version=v$1 run" % [version]

task release, "build release bin":
  exec "nimble -d:release -d:Version=v$1 build" % [version]
  withDir binDir:
    let staticDir = "public"
    if staticDir.dirExists:
      exec "rm -r $1" % [staticDir]
    exec "cp -r $1 $2" % [".." / srcDir / "html", staticDir]
    "README.txt".writeFile("copy public dir to ~/.config/$1/$2\n" % [bin[0], staticDir])
