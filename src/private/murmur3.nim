{.compile: "include/murmur3.c".}

proc MurmurHash3_x64_128*(key: cstring, len: int, seed: uint32, out_hashes: var array[2, int64]): void {.importc: "MurmurHash3_x64_128".}

proc MurmurHash3_x86_32*(key: cstring, len: int, seed: uint32, out_hashes: var array[2, int32]): void {.importc: "MurmurHash3_x86_32".}