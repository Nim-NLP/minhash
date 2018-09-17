{.compile: "include/murmur3.c".}

proc MurmurHash3_x64_128*(key: cstring, len: int, seed: uint32, out_hashes: var array[2, uint64]): void {.importc: "MurmurHash3_x64_128".}

proc MurmurHash3_x86_32*(key: cstring, len: int, seed: uint32, out_hashes: var array[2, uint32]): void {.importc: "MurmurHash3_x86_32".}

proc MurmurHash3_x86_128*(key: cstring, len: int, seed: uint32, out_hashes: var array[2, uint32]): void {.importc: "MurmurHash3_x86_128".}