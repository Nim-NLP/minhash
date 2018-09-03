# minhash
# Copyright zhoupeng
# Nim implementation of minhash algoritim


def minhash_64(char* c_str, int strlen,
               np.ndarray[dtype=np.uint32_t, ndim=1] seeds not None,
               int char_ngram):
    """Perform shingling and compute minhash of each shingle.
    Creates `char_ngram` length shingles from input string `c_str` and computes
    `len(seeds)` number 128bit min hashes for each shingle. A shingle is a
    character ngram of length `char_ngram`, consecutive shingles are taken over
    a sliding window.
    """
    cdef uint32_t num_seeds = len(seeds)
    cdef np.ndarray[np.uint64_t, ndim=1] fingerprint = \
        np.zeros((num_seeds, ), dtype=np.uint64)

    cdef uint64_t INT64_MAX = 9223372036854775807
    cdef uint64_t hashes[2]
    cdef uint64_t minhash

    # memory view to the numpy array - this should be free of any python
    cdef uint64_t [:] mem_view = fingerprint
    cdef uint32_t i, s
    with nogil:
        for s in range(num_seeds):
            minhash = INT64_MAX
            for i in range(strlen - char_ngram + 1):
                MurmurHash3_x64_128(c_str, char_ngram, seeds[s], hashes)
                if hashes[0] < minhash:
                    minhash = hashes[0]
                c_str += 1

            # store the current minhash
            mem_view[s] = minhash

            # reset string pointer for next hash
            c_str -= strlen - char_ngram + 1
    return fingerprint


@cython.boundscheck(False) # turn of bounds-checking for entire function
def minhash_32(char* c_str, int strlen,
               np.ndarray[dtype=np.uint32_t, ndim=1] seeds not None,
               int char_ngram):
    """Perform shingling and compute minhash of each shingle.
    Creates `char_ngram` length shingles from input string `c_str` and computes
    `len(seeds)` number 128bit min hashes for each shingle. A shingle is a
    character ngram of length `char_ngram`, consecutive shingles are taken over
    a sliding window.
    """
    cdef uint32_t num_seeds = len(seeds)
    cdef np.ndarray[np.uint32_t, ndim=1] fingerprint = \
        np.zeros((num_seeds, ), dtype=np.uint32)

    cdef int32_t INT32_MAX = 4294967295
    cdef int32_t hash_[1]
    cdef int32_t minhash

    # memory view to the numpy array - this should be free of any python
    cdef uint32_t [:] mem_view = fingerprint
    cdef uint32_t i, s
    with nogil:
        for s in range(num_seeds):
            minhash = INT32_MAX
            for i in range(strlen - char_ngram + 1):
                MurmurHash3_x86_32(c_str, char_ngram, seeds[s], hash_)
                if hash_[0] < minhash:
                    minhash = hash_[0]
                c_str += 1

            # store the current minhash
            mem_view[s] = minhash

            # reset string pointer for next hash
            c_str -= strlen - char_ngram + 1
    return fingerprint
    
class MinHasher(object):
    def __init__(self, seeds, char_ngram=8, random_state=None, hashbytes=8):
        """The MinHasher creates fingerprints from raw documents.
        The MinHasher facilitates the creation of MinHash document
        fingerprints. It creates overlapping character ngram shingles of length
        `char_ngram` using a sliding window over the document. To preprocessing
        to the documents is done, they are shingled as is.
        Parameters:
        -----------
        seeds: np.ndarray, int
            A Numpy array of 32bit unsigned integers to use as seeds to
            initialise hash functions, or a single integer for the number of
            seeds to create. A minhash is computed for each hash function
            derived from seeds.
        char_ngram: int
            The number of consecutive characters to include in a sliding window
            when creating the document shingles.
        random_state: None, int, np.random.RandomState
            A random state to initialise the random number generator with.
        """
        self.char_ngram = char_ngram
        random_state = np.random.RandomState(random_state)
        if hashbytes not in set([4, 8, 16]):
            raise ValueError('Hash has to be 4, 8 or 16 bytes.')

        if hashbytes == 16:
            raise NotImplementedError()

        self.hashbytes = hashbytes
        if isinstance(seeds, np.ndarray):
            self._seeds = seeds.astype(np.uint32)
        else:
            self._seeds = np.array(random_state.randint(0, 1e6, seeds),
                                   dtype=np.uint32)

    @property
    def num_seeds(self):
        return len(self._seeds)

    @lru_cache(maxsize=10000)
    def fingerprint(self, text):
        if isinstance(text, str):
            text = text.encode('utf8')
        if self.hashbytes == 4:
            fingerprint = minhash_32(text, len(text),
                                     self._seeds, self.char_ngram)
        elif self.hashbytes == 8:
            fingerprint = minhash_64(text, len(text),
                                     self._seeds, self.char_ngram)
        return fingerprint

    def jaccard(self, doc1, doc2):
        if isinstance(doc1, str):
            f_a = set(self.fingerprint(doc1))
        else:
            f_a = doc1  # assume it's z fingerprint
        if isinstance(doc1, str):
            f_b = set(self.fingerprint(doc2))
        else:
            f_b = doc2
        return len(f_a & f_b) / len(f_a | f_b)