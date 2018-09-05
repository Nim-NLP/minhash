import minhash

let hasher =  initMinHasher[MinHasher64](100,3)
assert hasher.jaccard("This is a doc", "This is a doc") == 1

let high_j = hasher.jaccard("This is a doc", "That is a doc")
let low_j = hasher.jaccard("This is a doc", "Cats in a tree")
assert 0 <= low_j 
assert low_j < high_j 
assert high_j <= 1