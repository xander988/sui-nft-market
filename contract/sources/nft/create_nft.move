// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::create_nft {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::Option;
    use std::option;
    use std::vector;
    use swift_nft::tags;

    /// An SWIFT NFT that can be minted by anybody
    struct SWIFTNFT has key, store {
        id: UID,
        /// Name for the asset.
        name: string::String,
        /// Description of the asset.
        description: string::String,
        /// URL pointing to the asset's image.
        url: Url,
        /// Object ID of the NFT's collection.
        collection_id: Option<ID>,
        /// Symbol of the asset.
        symbol: Option<string::String>,
        /// URL pointing to the asset's animation.
        animation_url: Option<string::String>,
        /// URL pointing to an external URL defining the asset  e.g. a game's main site.
        external_url: Option<string::String>,
        /// Array of keys of attributes defining the characteristics of the asset.
        attribute_keys: vector<string::String>,
        /// Array of values of attributes defining the characteristics of the asset.
        attribute_values: vector<string::String>,
    }


    // ===== Events =====

    struct NFTMintedEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &SWIFTNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &SWIFTNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &SWIFTNFT): &Url {
        &nft.url
    }


    /// Create a new swift_nft
    public entry fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        collection_id: vector<u8>,
        symbol: vector<u8>,
        animation_url: vector<u8>,
        external_url: vector<u8>,
        attribute_keys: vector<vector<u8>>,
        attribute_values: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        let collection_id = if (vector::length(&collection_id) > 0) {
            option::some(object::id_from_bytes(collection_id))
        }else {
            option::none<ID>()
        };

        let symbol = if (vector::length(&symbol) > 0) {
            option::some(string::utf8(symbol))
        }else {
            option::none<string::String>()
        };


        let animation_url = if (vector::length(&animation_url) > 0) {
            option::some(string::utf8(animation_url))
        }else {
            option::none<string::String>()
        };

        let external_url = if (vector::length(&external_url) > 0) {
            option::some(string::utf8(external_url))
        }else {
            option::none<string::String>()
        };

        let sender = tx_context::sender(ctx);
        let nft = SWIFTNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            collection_id,
            symbol,
            animation_url,
            external_url,
            attribute_keys: tags::to_string_vector(&mut attribute_keys),
            attribute_values: tags::to_string_vector(&mut attribute_values),
        };

        event::emit(NFTMintedEvent {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);
    }

    /// Transfer `nft` to `recipient`
    public entry fun transfer(
        nft: SWIFTNFT, recipient: address, _: &mut TxContext
    ) {
        transfer::transfer(nft, recipient)
    }

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description(
        nft: &mut SWIFTNFT,
        new_description: vector<u8>,
        _: &mut TxContext
    ) {
        nft.description = string::utf8(new_description)
    }

    /// Permanently delete `nft`
    public entry fun burn(nft: SWIFTNFT, _: &mut TxContext) {
        let SWIFTNFT {
            id,
            name: _,
            description: _,
            url: _,
            collection_id: _,
            symbol: _,
            animation_url: _,
            external_url: _,
            attribute_keys: _,
            attribute_values: _, } = nft;
        object::delete(id)
    }
}
