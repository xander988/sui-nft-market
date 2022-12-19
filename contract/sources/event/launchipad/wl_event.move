// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::wl_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::whitelist ;

    struct ActivityCreatedEvent<phantom Item, phantom Market>has copy, drop {
        activity_id: ID,
        sale_id: ID,
    }

    struct WLCreatedEvent<phantom Item, phantom Market>has copy, drop {
        white_list: ID,
        creator: address,
    }

    struct WLDestoryEvent<phantom Item, phantom Market>has copy, drop {
        white_list: ID,
        creator: address,
    }

    public(friend) fun activity_created_event<Item, Market>(activity_id: ID,
                                                            sale_id: ID) {
        event::emit(ActivityCreatedEvent<Item, Market> {
            activity_id,
            sale_id
        })
    }

    public(friend) fun whitelist_created_event<Item, Market>(white_list: ID,
                                                             creator: address, ) {
        event::emit(WLCreatedEvent<Item, Market> {
            white_list,
            creator
        })
    }

    public(friend) fun whitelist_destory_event<Item, Market>(white_list: ID,
                                                             creator: address, ) {
        event::emit(WLDestoryEvent<Item, Market> {
            white_list,
            creator
        })
    }
}
