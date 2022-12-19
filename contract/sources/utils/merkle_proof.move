// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::merkle_proof {
    use std::vector;
    //use sui::ecdsa;


    const ETwoVectorLengthMismatch: u64 = 0;

    public fun verify(proof: vector<vector<u8>>, root: vector<u8>, leaf: vector<u8>): bool {
        processProof(proof, leaf) == root
    }


    fun processProof(proof: vector<vector<u8>>, leaf: vector<u8>): vector<u8> {
        let computedHash = leaf;
        let i = 0;
        let length_proof = vector::length(&proof);
        while (i != length_proof) {
            computedHash = hashPair(computedHash, *vector::borrow(&proof, i));
            i = i + 1
        };
        computedHash
    }

    fun compare(a: vector<u8>, b: vector<u8>): bool {
        let length_a = vector::length(&a);
        let length_b = vector::length(&b);
        assert!(length_b == length_a, ETwoVectorLengthMismatch);
        let i = 0;
        while (i < length_a) {
            let tep_a = *vector::borrow(&a, i);
            let tep_b = *vector::borrow(&b, i);
            if (tep_b < tep_a) {
                return true
            }else if (tep_a < tep_b) {
                return false
            };
            i = i + 1
        };
        return true
    }


    fun hashPair(a: vector<u8>, b: vector<u8>): vector<u8> {
        return if (compare(a, b)) {
            efficientHash(a, b)
        }else {
            efficientHash(b, a)
        }
    }

    fun efficientHash(a: vector<u8>, b: vector<u8>): vector<u8> {
        vector::append(&mut a, b);
        //return ecdsa::keccak256(&a)
          a
    }
}
