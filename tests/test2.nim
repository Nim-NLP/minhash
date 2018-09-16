import minhash
import strutils
import sets
import sequtils
# [20, 40, 50]
let hasher =  initMinHasher[uint64](100,3)
# very small band width => always find duplicates
var lsh = initLocalitySensitive[uint64](hasher, 20)
let 
    short_doc = "This is a simple document"
    another_doc = "Some text about animals."
    long_doc = "A much longer document that contains lots of information" &
        "different words. The document produces many more shingles."

assert  lsh.is_duplicate(short_doc) == false
lsh.add_doc(short_doc, "0")
assert lsh.get_duplicates_of(short_doc) == toSet(["0"])
assert lsh.is_duplicate(short_doc, "0")
assert lsh.is_duplicate(short_doc)

assert lsh.is_duplicate(long_doc) == false
lsh.add_doc(long_doc, "1")
lsh.add_doc(another_doc, "2")
assert lsh.is_duplicate(another_doc)

assert lsh.is_duplicate(long_doc, "1")
assert lsh.is_duplicate(long_doc)

let words = long_doc.split()
var long_doc_missing_word = newSeq[string]()
long_doc_missing_word.add(words[0])
long_doc_missing_word.add(words[2..^1])
var longstr=long_doc_missing_word.join(" ")
assert lsh.get_duplicates_of(longstr) == toSet(["1"])
assert lsh.is_duplicate(longstr)
assert lsh.is_duplicate(long_doc & " Word.")

assert lsh.get_all_duplicates().len == 0
lsh.add_doc(longstr, "3")

assert lsh.get_all_duplicates() == toSet([(a:"1", b:"3")])

lsh.add_doc(longstr, "4")

assert lsh.get_all_duplicates().intersection(toSet([(a:"1",b:"4"), (a:"4", b:"3"), (a:"1", b:"3")])).len == 3