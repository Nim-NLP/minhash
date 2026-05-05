# Package

version       = "0.1.0"
author        = "zhoupeng"
description   = "Nim implementation of minhash algoritim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.0"

task test, "Run tests":
  exec "nim c -r tests/test1.nim"
  exec "nim c -r tests/test2.nim"
