module swift_nft::sale_event {
    use sui::object::{ID};
    use sui::event;
    friend swift_nft::sale;

    struct CreateSaleEvent<phantom Item, phantom Market> has copy, drop {
        sale_id: ID,
        white_list: bool,
    }

    struct ListItemEvent<phantom Item, phantom Market> has copy, drop {
        sale_id: ID,
        item_ids: vector<ID>,
    }

    struct UnlistItemEvent<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        item_ids: vector<ID>,
    }

    struct ModityWhiteListEvent<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        stauts: bool,
    }

    struct WithdrawNFT<phantom Item, phantom Market>has copy, drop {
        sale_id: ID,
        item_id: ID,
    }


    public(friend) fun create_sale_event<Item, Market>(sale_id: ID, white_list: bool) {
        event::emit(CreateSaleEvent<Item, Market> {
            sale_id,
            white_list
        })
    }


    public(friend) fun list_item_event<Item, Market>(sale_id: ID, item_ids: vector<ID>) {
        event::emit(ListItemEvent<Item, Market> {
            sale_id,
            item_ids
        })
    }

    public(friend) fun unlist_item_event<Item, Market>(sale_id: ID, item_ids: vector<ID>) {
        event::emit(UnlistItemEvent<Item, Market> {
            sale_id,
            item_ids
        })
    }

    public(friend) fun modity_whitelist_event<Item, Market>(sale_id: ID, stauts: bool) {
        event::emit(ModityWhiteListEvent<Item, Market> {
            sale_id,
            stauts
        })
    }

    public(friend) fun withdraw_item_event<Item, Market>(sale_id: ID, item_id: ID) {
        event::emit(WithdrawNFT<Item, Market> {
            sale_id,
            item_id
        })
    }
}
