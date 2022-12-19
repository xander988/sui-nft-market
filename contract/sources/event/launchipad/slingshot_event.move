// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::slingshot_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::slingshot;

    struct SlingshotCreatedEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }

    struct SalesAddEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }

    struct SalesRemoveEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }

    struct LiveChangeEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        status: bool
    }

    struct AdminUpdateEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        admin: address,
    }

    struct SalesBorrowEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        operator: address,
    }

    public(friend) fun slingshot_create_event<Item, Market>(slingshot_id: ID,
                                                            sales: vector<ID>) {
        event::emit(SlingshotCreatedEvent<Item, Market> {
            slingshot_id,
            sales
        })
    }


    public(friend) fun sales_add_event<Item, Market>(slingshot_id: ID,
                                                     sales: vector<ID>) {
        event::emit(SalesAddEvent<Item, Market> {
            slingshot_id,
            sales
        })
    }

    public(friend) fun sales_remove_event<Item, Market>(slingshot_id: ID,
                                                        sales: vector<ID>) {
        event::emit(SalesRemoveEvent<Item, Market> {
            slingshot_id,
            sales
        })
    }

    public(friend) fun live_change_event<Item, Market>(slingshot_id: ID, status: bool) {
        event::emit(LiveChangeEvent<Item, Market> {
            slingshot_id,
            status
        })
    }

    public(friend) fun admin_update_event<Item, Market>(slingshot_id: ID, admin: address) {
        event::emit(AdminUpdateEvent<Item, Market> {
            slingshot_id,
            admin
        })
    }


    public(friend) fun sales_borrow_event<Item, Market>(slingshot_id: ID, operator: address) {
        event::emit(SalesBorrowEvent<Item, Market> {
            slingshot_id,
            operator
        })
    }
}
