import minhash

block:
    let hasher =  initMinHasher[uint64](100)
    assert hasher.jaccard("This is a doc", "This is a doc") == 1
    let high_j = hasher.jaccard("This is a doc", "That is a doc")
    let low_j = hasher.jaccard("This is a doc", "Cats in a tree")
    assert 0 <= low_j 
    assert low_j < high_j 
    assert high_j <= 1
    
block:
    let hasher =  initMinHasher[uint32](100)
    assert hasher.jaccard("This is a doc", "This is a doc") == 1

    let high_j = hasher.jaccard("This is a doc", "That is a doc")
    let low_j = hasher.jaccard("This is a doc", "Cats in a tree")
    assert 0 <= low_j 
    assert low_j < high_j 
    assert high_j <= 1
