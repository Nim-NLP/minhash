# minhash
# Copyright zhoupeng
# Nim implementation of minhash algoritim
# port from https://github.com/mattilyra/LSH/blob/3db37cf07eefa3276e7409b12e73f30f596236ae/lsh/cMinhash.pyx
import random
import sets
import sequtils
import minhash/murmur3
import minhash/combinatorics
import typetraits
import tables
import hashes

export sets

const 
    UINT64_MAX = 18446744073709551615'u64
    UINT32_MAX = 4294967295'u32
    defaultRandMax:int32 = 1000000
    msgDivisible = "The number of seeds in the fingerprint must" &
        "be divisible by the number of bands"

type 
    MinHasher*[T] = object
        char_ngram:int
        seeds:seq[uint32]
        num_seeds:int
    Bin[T] = TableRef[seq[T], HashSet[string]]
    LocalitySensitive*[T] = object
        hasher: MinHasher[T]
        bins:TableRef[int,Bin[T]]
        num_bands:int
        fingerprints:TableRef[string,seq[T]]
        band_width:int

iterator slide(content:string, width=4) : string {.closure.} =
    let 
        maxLen = max(content.len - width + 1, 1)
    var pos:int
    for i in 0..<maxLen:
        pos = i + width
        yield content[i..<pos]

proc minhash64*(str:string, seeds:openArray[uint32],char_ngram:int) : auto {.noInit.} =
    let num_seeds = seeds.len
    var 
        hashes:array[2,uint64]
        ngrams:string
        curHash:uint64
    result = newSeq[UINT64_MAX](num_seeds)
    for s in 0..<num_seeds:
        curHash = UINT64_MAX
        for ngrams in slide(str,char_ngram):
            MurmurHash3_x64_128(ngrams, char_ngram, seeds[s], hashes)
            if  hashes[0] < curHash:
                curHash = hashes[0]
        result[s] = curHash

proc minhash32*(str: string, seeds:openArray[uint32],char_ngram:int) : auto {.noInit.}=
    let num_seeds = seeds.len
    var 
        hashes:array[2,uint32]
        ngrams:string
        curHash:uint32
    result = newSeq[UINT32_MAX](num_seeds)
    for s in 0..<num_seeds:
        curHash = UINT32_MAX
        for ngrams in slide(str,char_ngram):
            MurmurHash3_x86_32(ngrams, char_ngram, seeds[s], hashes)
            if hashes[0] < curHash:
                curHash = hashes[0]
        result[s] = curHash
    
proc fingerprint*[T](self:MinHasher[T], text:string): seq[T] =
    when type(T) is uint64:
        result = minhash_64(text, self.seeds, self.char_ngram)
    elif type(T) is uint32:
        result = minhash32(text, self.seeds, self.char_ngram)

proc jaccard*[T](self:MinHasher[T], doc1, doc2:string):float=
    let 
        f_a = toSet(self.fingerprint(doc1))
        f_b = toSet(self.fingerprint(doc2))
    return len( f_a.intersection( f_b)) / len( f_a.union( f_b))  

proc jaccard*[T](self:MinHasher[T], fingerprint1, fingerprint2:openArray[T]):float=
    let 
        f_a = toSet(fingerprint1)
        f_b = toSet(fingerprint2)
    return len( f_a.intersection( f_b)) / len( f_a.union( f_b))     
    
proc initMinHasher*[T](seeds:seq[SomeInteger], char_ngram=8,random_state=0):MinHasher[T]=
    result.char_ngram = char_ngram
    result.seeds = seeds
    result.num_seeds = len(seeds)

proc initMinHasher*[T](num_seeds:int, char_ngram=8,random_state=0):MinHasher[T]=
    result.char_ngram = char_ngram
    result.num_seeds = num_seeds
    var sed = newSeq[uint32](num_seeds)
    result.seeds = map(sed,proc(x:uint32):uint32 = cast[uint32](rand(defaultRandMax)))

proc initLocalitySensitive*[T](hasher: MinHasher[T] , num_bands=10):LocalitySensitive[T] =
    result.bins = newTable[int,Bin[T]]()
    for i in 0..<num_bands:
        result.bins[i] = newTable[seq[T], HashSet[string]]()
    result.hasher = hasher
    doAssert hasher.num_seeds mod num_bands == 0, msgDivisible
    result.band_width = hasher.num_seeds div num_bands
    result.num_bands = num_bands
    result.fingerprints = newTable[string,seq[T]]()

proc getBins[T](self:LocalitySensitive[T], fingerprint:seq[T]):seq[seq[T]] =
    result = fingerprint.distribute(self.band_width )

# proc clear(self):
#     self.bins = [defaultdict(set) for _ in range(self.num_bands)]
#     self.hasher.fingerprint.cache_clear()

proc add_doc*[T](self:LocalitySensitive[T], doc:string, doc_id:string) =
    let fingerprint = self.hasher.fingerprint(doc)
    self.add_fingerprint(fingerprint, doc_id)

proc add_fingerprint*[T](self:LocalitySensitive[T], fingerprint:seq[T], doc_id:string) =
    self.fingerprints[doc_id] = fingerprint
    for bin_i, bucket in self.getBins(fingerprint).pairs:
        if self.bins[bin_i].len > 0 and self.bins[bin_i].hasKey(bucket):
            self.bins[bin_i][bucket].incl doc_id
        else:
            discard self.bins[bin_i].mgetOrPut(bucket, toSet([doc_id]))

proc filter_candidates*[T](self:LocalitySensitive[T], candidate_id_pairs:HashSet[tuple[a:string,b:string]], min_jaccard:float):HashSet[tuple[a:string,b:string]]=
    var jaccard:float
    for id1, id2 in candidate_id_pairs.items:
        # todo id1, id2 may not be contained in data
        jaccard = self.hasher.jaccard(self.fingerprints[id1],self.fingerprints[id2])                  
        if jaccard > min_jaccard:
            result.incl((id1, id2))

proc remove_id*[T](self:LocalitySensitive[T], doc_id:string) =
    let fingerprint = self.fingerprints[doc_id]
    for bin_i, bucket in self.getBins(fingerprint).pairs:
        self.bins[bin_i][bucket].remove(doc_id)

    del self.fingerprints[doc_id]

# proc remove_doc(self:LocalitySensitive, doc:string) =
#     let fingerprint = self.hasher.fingerprint(doc)
#     doc_ids = {id for id, finger in self.fingerprints.items()
#                 if all(a == b for a, b in zip(finger, fingerprint))}
#     for i in doc_ids:
#         self.remove_id(i)

proc get_all_duplicates*[T](self:LocalitySensitive[T], min_jaccard = 0.0): HashSet[tuple[a:string,b:string]]{.noInit.} =
    var candidates = initSet[tuple[a:string,b:string]]()
    for b in self.bins.values:
        for bucket in b.keys:
            if len(b[bucket]) > 1:
                for x in combinations(toSeq(b[bucket].items()),2):
                    candidates.incl( (a:x[0],b:x[1]) )
    if min_jaccard != 0.0:
        result = self.filter_candidates(candidates, min_jaccard)
    else:
        result = candidates

proc get_duplicates_of*[T](self:LocalitySensitive[T], doc="", doc_id="", min_jaccard = 0.0): HashSet[string] = 
    var 
        fingerprint:seq[T]
    result = initSet[string]()
    if doc_id != "" and doc_id in self.fingerprints:
        fingerprint = self.fingerprints[doc_id]
    elif doc != "":
        fingerprint = self.hasher.fingerprint(doc)
    else:
        discard
        # raise ValueError("Must provide a document or a known document id")
    for bin_i, bucket in self.getBins(fingerprint).pairs:
        if self.bins[bin_i].len > 0 and self.bins[bin_i].hasKey(bucket):
            result.incl self.bins[bin_i][bucket]

    # if min_jaccard != 0:
    #     result = {x for x in candidates
    #             if self.hasher.jaccard(fingerprint,
    #                                     self.fingerprints[x]) > min_jaccard}

proc is_duplicate*[T](self:LocalitySensitive[T], doc:string, doc_id=""):bool =
    return len(self.get_duplicates_of(doc, doc_id)) > 0
    
when isMainModule:
    let hasher =  initMinHasher[uint64](100,3)
    assert hasher.jaccard("This is a doc", "This is a doc") == 1

    let high_j = hasher.jaccard("This is a doc", "That is a doc")
    let low_j = hasher.jaccard("This is a doc", "Cats in a tree")
    assert 0 <= low_j 
    assert low_j < high_j 
    assert high_j <= 1
