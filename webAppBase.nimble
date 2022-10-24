# Package

version       = "0.1.0"
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
requires "htmlgenerator"


# Tasks

task r, "build and run":
  exec "nimble build"
  exec "nimble ex"

import os
task ex, "run without build":
  withDir binDir:
    exec "if [ ! -e public ]; then ln -s ../src/html public; fi"
    for b in bin:
      exec "." / b
