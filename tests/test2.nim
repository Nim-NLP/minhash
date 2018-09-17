import minhash
import strutils
import sets
import sequtils
# [20, 40, 50]
let hasher =  initMinHasher[uint64](100)
# very small band width => always find duplicates
var lsh = initLocalitySensitive[uint64](hasher, 20)
let 
    short_doc = "This is a simple document"
    another_doc = "Some text about animals."
    long_doc = "A much longer document that contains lots of information" &
        "different words. The document produces many more shingles."

assert  lsh.isDuplicate(short_doc) == false
lsh.add(short_doc, "0")
assert lsh.getDuplicatesOf(short_doc) == toSet(["0"])
assert lsh.isDuplicate(short_doc, "0")
assert lsh.isDuplicate(short_doc)

assert lsh.isDuplicate(long_doc) == false
lsh.add(long_doc, "1")
lsh.add(another_doc, "2")
assert lsh.isDuplicate(another_doc)

assert lsh.isDuplicate(long_doc, "1")
assert lsh.isDuplicate(long_doc)

let words = long_doc.split()
var long_doc_missing_word = newSeq[string]()
long_doc_missing_word.add(words[0])
long_doc_missing_word.add(words[2..^1])
var longstr=long_doc_missing_word.join(" ")
assert lsh.getDuplicatesOf(longstr) == toSet(["1"])
assert lsh.isDuplicate(longstr)
assert lsh.isDuplicate(long_doc & " Word.")

assert lsh.getDuplicates().len == 0
lsh.add(longstr, "3")

assert lsh.getDuplicates() == toSet([(a:"1", b:"3")])

lsh.add(longstr, "4")

assert lsh.getDuplicates().intersection(toSet([(a:"1",b:"4"), (a:"4", b:"3"), (a:"1", b:"3")])).len == 3