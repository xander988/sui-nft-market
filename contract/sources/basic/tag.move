module swift_nft::tags {
    // TODO: Consider using `VecSet` instead of `VecMap` since
    // keys are simply indices
    use std::vector;
    use std::string::{Self, String};
    use sui::vec_map::{Self, VecMap};

    /// @notice Struct representing a enumeration of Nft Tags.
    struct Tags has copy, drop, store {
        enumerations: VecMap<u64, String>
    }

    public fun empty(): Tags {
        Tags { enumerations: vec_map::empty() }
    }

    public fun from_vec_string(v: &mut vector<String>): Tags {
        vector::reverse(v);
        let i = 0;
        let len = vector::length(v);

        let enum = vec_map::empty();

        while (i < len) {
            let elem = vector::pop_back(v);
            vec_map::insert(&mut enum, i, elem);

            i = i + 1;
        };

        Tags { enumerations: enum }
    }

    public fun from_vec_u8(v: &mut vector<vector<u8>>): Tags {
        let new_v = to_string_vector(v);
        from_vec_string(&mut new_v)
    }

    public fun push_tag(
        self: &mut Tags,
        type: String,
    ) {
        let vec = &mut self.enumerations;

        // Computes last index of the enum
        let index = vec_map::size(vec);

        vec_map::insert(vec, index + 1, type);
    }

    public fun pop_tag(
        self: &mut Tags,
        index: u64,
    ) {
        let vec = &mut self.enumerations;

        vec_map::remove_entry_by_idx(vec, index);
    }

    public fun to_string_vector(
        vec: &mut vector<vector<u8>>
    ): vector<String>
    {
        let new_vec: vector<String> = vector::empty();

        let len = vector::length(vec);

        if (len == 0) {
            return new_vec
        };

        let i = 0;
        while (i < len) {
            let e = string::utf8(vector::pop_back(vec));
            vector::push_back(&mut new_vec, e);
            i = i + 1;
        };

        vector::reverse(&mut new_vec);
        new_vec
    }
}