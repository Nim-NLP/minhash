# minhash
# Copyright zhoupeng
# Nim implementation of minhash algoritim
import random
import sets
import sequtils
import private/murmur3

const 
    INT64_MAX = 9223372036854775807'u64
    INT32_MAX = 4294967295'u32

type 
    MinHasher64* = object
        char_ngram:int
        seeds:seq[uint32]

type 
    MinHasher32* = object
        char_ngram:int
        seeds:seq[uint32]

proc zeros*(N: int, A: typedesc): auto = newSeq[A](N)

proc minhash64*(str:string, seeds:openArray[uint32],char_ngram:int) : auto =
    let strlen = str.len
    let num_seeds = seeds.len
    var 
        hashes:array[2,int64]
        minhash:uint64
    result = zeros(num_seeds,uint64 )
    for s in 0..<num_seeds:
        minhash = INT64_MAX
        for i in 0..<(strlen - char_ngram + 1):
            MurmurHash3_x64_128(str, char_ngram, cast[uint32](result[s]), hashes)
            if  cast[uint64](hashes[0]) < minhash:
                minhash = cast[uint64](hashes[0])
        result[s] = minhash

proc minhash32*(str: string, seeds:openArray[uint32],char_ngram:int) : auto =
    let strlen = str.len
    let num_seeds = seeds.len
    var 
        hashes:array[2,int32]
        minhash:uint32
    result = zeros(num_seeds,uint32 )
    for s in 0..<num_seeds:
        minhash = INT32_MAX
        for i in 0..<(strlen - char_ngram + 1):
            MurmurHash3_x86_32(str, char_ngram, seeds[s], hashes)
            if cast[uint32](hashes[0]) < minhash:
                minhash = cast[uint32](hashes[0])
        result[s] = minhash

proc fingerprint*(self:MinHasher32, text:string): auto =
 
    result = minhash_32(text, self.seeds, self.char_ngram)
    
proc fingerprint*(self:MinHasher64, text:string): auto =

    result = minhash_64(text, self.seeds, self.char_ngram)

proc jaccard* [T](self:T, doc1, doc2:string):int=
    let 
        f_a = toSet(self.fingerprint(doc1))
        f_b = toSet(self.fingerprint(doc2))
   
    return len( intersection(f_a , f_b)) div len( union(f_a, f_b))
    
proc initMinHasher*[T](seeds:seq[SomeInteger], char_ngram=8,random_state=0):T=
    result.char_ngram = char_ngram
    let rand = initRand(random_state)
    result.seeds = seeds

proc initMinHasher* [T](seeds:int, char_ngram=8,random_state=0):T=
    result.char_ngram = char_ngram
    var ran = initRand(0)
    var sed = newSeq[uint32](seeds)
    result.seeds = map(sed,proc(x:uint32):uint32 = cast[uint32](ran.rand( 1e6)))
    
when isMainModule:
    var str = "aaa"
    echo minhash64(str,[1'u32,2,3,4,5],2)
    echo minhash32(str,[1'u32,2,3,4,5],2)
    discard initMinHasher[MinHasher64](1,2)