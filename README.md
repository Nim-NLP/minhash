# minhash

[![CI](https://github.com/Nim-NLP/minhash/actions/workflows/ci.yml/badge.svg)](https://github.com/Nim-NLP/minhash/actions/workflows/ci.yml)

Nim implementation of the [MinHash](https://en.wikipedia.org/wiki/MinHash) algorithm with Locality Sensitive Hashing (LSH) for near-duplicate detection.

Ported from [mattilyra/LSH](https://github.com/mattilyra/LSH/).

## Requirements

- Nim >= 1.6.0

## Installation

```bash
nimble install minhash
```

## Usage

```nim
import minhash

let hasher = initMinHasher[uint64](100)
var lsh = initLocalitySensitive[uint64](hasher, num_bands = 10)

lsh.add("This is a simple document", "doc1")
lsh.add("This is another document", "doc2")

# Find all duplicate pairs above a Jaccard threshold
let dupes = lsh.getDuplicates(min_jaccard = 0.5)
for d in dupes:
  echo d.a, " ~ ", d.b

# Find duplicates of a specific document
let similar = lsh.getDuplicatesOf(doc = "This is a simple document")
```

## Running Tests

```bash
nimble test
```

## License

MIT
