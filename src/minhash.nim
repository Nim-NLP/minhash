# minhash
# Copyright zhoupeng
# Nim implementation of minhash algoritim
import random
import sets
import sequtils
import private/murmur3

const 
    UINT64_MAX = 9223372036854775807'u64
    UINT32_MAX = 4294967295'u32
    defaultRandMax:int32 = 1000000

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
        hashes:array[2,uint64]
        minhash:uint64
    result = zeros(num_seeds,uint64 )
    for s in 0..<num_seeds:
        minhash = UINT64_MAX
        for i in 0..<(strlen - char_ngram + 1):
            MurmurHash3_x64_128(str, char_ngram, cast[uint32](result[s]), hashes)
            if  hashes[0] < minhash:
                minhash = hashes[0]
        result[s] = minhash

proc minhash32*(str: string, seeds:openArray[uint32],char_ngram:int) : auto =
    let strlen = str.len
    let num_seeds = seeds.len
    var 
        hashes:array[2,uint32]
        minhash:uint32
    result = zeros(num_seeds,uint32 )
    for s in 0..<num_seeds:
        minhash = UINT32_MAX
        for i in 0..<(strlen - char_ngram + 1):
            MurmurHash3_x86_32(str, char_ngram, seeds[s], hashes)
            if hashes[0] < minhash:
                minhash = hashes[0]
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
    result.seeds = seeds

proc initMinHasher* [T](seeds:int, char_ngram=8,random_state=0):T=
    result.char_ngram = char_ngram
    var sed = newSeq[uint32](seeds)
    result.seeds = map(sed,proc(x:uint32):uint32 = cast[uint32](rand(defaultRandMax)))

when isMainModule:
    
    let hasher =  initMinHasher[MinHasher64](100)
    assert hasher.jaccard("This is a doc", "This is a doc") == 1

    let high_j = hasher.jaccard("This is a doc", "That is a doc")
    let low_j = hasher.jaccard("This is a doc", "Cats in a tree")
    echo low_j,"-",high_j
    assert 0 <= low_j 
    assert low_j < high_j 
    assert high_j <= 1