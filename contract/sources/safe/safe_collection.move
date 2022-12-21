// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::safe_collection {
    use sui::object::{UID,ID};
    use std::string::{String};


    ///flashloan
    struct Collection<phantom T,M: store,Royalty: store> has key, store {
        id: UID,
        /// Address that created this collection
        creator: address,
        /// Name of the collection. TODO: should this just be T.name?
        name: String,
        /// Description of the collection
        description: String,

        safe_id: ID,

        custom_metadata: M,

        royalty: Royalty,
    }




    public  fun get_royalty<Item: key+store,M: store,Royalty: store>(collection: &Collection<Item,M,Royalty>): &Royalty{
         &collection.royalty
    }



}
