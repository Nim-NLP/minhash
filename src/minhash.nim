# minhash
# Copyright zhoupeng
# Nim implementation of minhash algoritim
# import neo
import private/murmur3

const 
    INT64_MAX = 9223372036854775807
    INT32_MAX = 2147483647'i32


# type 
#     MinHasher = object
#         char_ngram:int
#         seeds:auto

proc zeros*(N: int, A: typedesc): auto = newSeq[A](N)

proc minhash64[T](str:string, seeds: openArray[T],char_ngram:int) : auto =
    let num_seeds = seeds.len
    let strlen = str.len
    var 
        hashes:array[2,int64]
        minhash:int64
    result = zeros(num_seeds,int64 )
    for s in 0..<num_seeds:
        minhash = INT64_MAX
        for i in 0..< (strlen - char_ngram + 1):
            MurmurHash3_x64_128(str, char_ngram, seeds[s], hashes)
            if hashes[0] < minhash:
                minhash = hashes[0]
        result[s] = minhash

proc minhash32(str: string, seeds: openArray[uint32],char_ngram:int) : auto =
    let num_seeds = seeds.len
    let strlen = str.len
    var 
        hashes:array[2,int32]
        minhash:int32
    result = zeros(num_seeds,uint32 )
    for s in 0..<num_seeds:
        minhash = INT32_MAX
        for i in 0..< (strlen - char_ngram + 1):
            MurmurHash3_x86_32(str, char_ngram, seeds[s], hashes)
            if hashes[0] < minhash:
                minhash = hashes[0]
        result[s] = cast[uint32](minhash)
        
when isMainModule:
    var str = "aaa"
    echo minhash64(str,[1'u32,2,3,4,5],2)
