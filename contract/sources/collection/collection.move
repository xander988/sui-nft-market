// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::collection {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};

    struct Collection<phantom T, M: store,Royalty> has key, store {
        id: UID,
        /// Address that created this collection
        creator: address,
        /// Name of the collection. TODO: should this just be T.name?
        name: String,
        /// Description of the collection
        description: String,
        /// The maximum number of instantiated NFT objects. Use U64_MAX if there is no max
        total_supply: u64,
        // ... more standard fields
        /// Custom metadata outside of the standard fields goes here
        custom_metadata: M,

        royalty: Royalty,

    }

    /// Proof that the given NFT is one of the limited `total_supply` NFT's in `Collection`
    struct CollectionProof has store {
        collection_id: ID
    }

    /// Grants the permission to mint `num_remaining` NFT's of type `T`
    /// The sum of `num_remaining` for all mint caps + the number of instantiated
    /// NFT's should be equal to `total_supply`.
    /// This is a fungible type to support parallel minting, giving a buyer the permission
    /// mint themselves, allowing multiple parties to mint, and so on.
    struct MintCap<phantom T> has key, store {
        id: UID,
        /// ID of the collection that this MintCap corresponds to
        collection: ID,
        /// Number of NFT's this cap can mint
        num_remaining: u64,
    }

    /// Grants the permission to mint `RoyaltyReceipt`'s for `T`.
    /// Receipts are required when paying for NFT's
    struct RoyaltyCap<phantom T> has key, store {
        id: UID,
        collection: ID,
    }

    /// Proof that the royalty policy for collection `T` has been satisfied.
    /// Needed to complete a sale of an NFT from a Collection<T>`
    struct RoyaltyReceipt<phantom T> {
        id: UID,
        collection: ID,
    }

    // /// Instantiate a collection for T.
    // /// To be called from the module initializer in the module that declares `T`
    // public fun create<T, M: store>(
    //     _witness: &T,
    //     name: String,
    //     total_supply: u64,
    //     ctx: &mut TxContext,
    // ): (Collection<T,M>, MintCap<T>, RoyaltyCap<T>) {
    //     abort(0)
    // }
    //
    // /// To be called from the module that declares `T`, when packing a value of type `T`.
    // /// The caller should place the `CollectionProof` in a field of `T`.
    // /// Decreases `num_remaining` by `amount`
    // public fun mint<T>(mint_cap: &mut MintCap<T>): CollectionProof {
    //     abort(0)
    // }
    //
    // /// To be called from the module that declares `T`.
    // /// The caller is responsible for gating usage of the `royalty_cap` with its
    // /// desired royalty policy.
    // public fun create_receipt<T>(royalty_cap: &mut RoyaltyCap<T>): RoyaltyReceipt<T> {
    //     abort(0)
    // }
    //
    // /// Split a big `mint_cap` into two smaller ones
    // public fun split<T>(mint_cap: &mut MintCap<T>, num: u64): MintCap<T> {
    //     abort(0)
    // }
    //
    // /// Combine two `MintCap`'s
    // public fun join<T>(mint_cap: &mut MintCap<T>, to_join: MintCap<T>) {
    //     abort(0)
    // }
}
