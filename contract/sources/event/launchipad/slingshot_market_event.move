// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::slingshot_market_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::slingshot_market;

    struct MarketCreatedEvent<phantom Item, phantom Market> has copy, drop {
        market_id: ID,
        start_time: u64,
        end_time: u64,
        price: u64,
        operator: address
    }

    struct SalesRemoveEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sale_id: ID,
        operator: address
    }

    struct ItemAdjustPriceEvent<phantom Item, phantom Market>has copy, drop {
        slingshot_id: ID,
        sale_id: ID,
        new_price: u64,
        operator: address
    }

    struct ItemPurchasedEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sale_id: ID,
        item_id: ID,
        price: u64,
        operator: address
    }


    public(friend) fun market_created_event<Item, Market>(market_id: ID,
                                                          start_time: u64,
                                                          end_time: u64,
                                                          price: u64, operator: address) {
        event::emit(MarketCreatedEvent<Item, Market> {
            market_id,
            start_time,
            end_time,
            price, operator
        })
    }


    public(friend) fun sale_remove_event<Item, Market>(slingshot_id: ID, sale_id: ID, operator: address) {
        event::emit(SalesRemoveEvent<Item, Market> {
            slingshot_id,
            sale_id,
            operator
        })
    }

    public(friend) fun item_adjust_price_event<Item, Market>(
        slingshot_id: ID,
        sale_id: ID,
        new_price: u64,
        operator: address
    ) {
        event::emit(ItemAdjustPriceEvent<Item, Market> {
            slingshot_id,
            sale_id,
            new_price,
            operator
        })
    }

    public(friend) fun item_purchased_event<Item, Market>(
        slingshot_id: ID,
        sale_id: ID,
        item_id: ID,
        price: u64,
        operator: address
    ) {
        event::emit(ItemPurchasedEvent<Item, Market> {
            slingshot_id,
            sale_id,
            item_id,
            price,
            operator
        })
    }
}
