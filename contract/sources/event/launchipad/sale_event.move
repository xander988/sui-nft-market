// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::sale_event {
    use sui::object::{ID};
    use sui::event;
    friend swift_nft::sale;

    struct SaleCreatedEvent<phantom Item, phantom Market> has copy, drop {
        sale_id: ID,
        white_list: bool,
    }

    struct ItemListEvent<phantom Item, phantom Market> has copy, drop {
        sale_id: ID,
        item_ids: vector<ID>,
    }

    struct ItemUnlistEvent<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        item_ids: vector<ID>,
    }

    struct WLStatusChangeEvent<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        stauts: bool,
    }

    struct ItemWithdraw<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        item_id: ID,
    }


    public(friend) fun sale_create_event<Item, Market>(sale_id: ID, white_list: bool) {
        event::emit(SaleCreatedEvent<Item, Market> {
            sale_id,
            white_list
        })
    }


    public(friend) fun item_list_event<Item, Market>(sale_id: ID, item_ids: vector<ID>) {
        event::emit(ItemListEvent<Item, Market> {
            sale_id,
            item_ids
        })
    }

    public(friend) fun item_unlist_event<Item, Market>(sale_id: ID, item_ids: vector<ID>) {
        event::emit(ItemUnlistEvent<Item, Market> {
            sale_id,
            item_ids
        })
    }

    public(friend) fun wl_status_change_event<Item, Market>(sale_id: ID, stauts: bool) {
        event::emit(WLStatusChangeEvent<Item, Market> {
            sale_id,
            stauts
        })
    }

    public(friend) fun item_withdraw_event<Item, Market>(sale_id: ID, item_id: ID) {
        event::emit(ItemWithdraw<Item, Market> {
            sale_id,
            item_id
        })
    }
}
