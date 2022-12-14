module swift_nft::slingshot_market_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::slingshot_market;

    struct  MarketCreateEvent<phantom Item,phantom Market> has copy,drop{
        market_id: ID,
        start_time: u64,
        end_time: u64,
        price: u64,
        operator: address
    }
    struct  RemoveSalesEvent<phantom Item,phantom Market> has copy,drop{
        slingshot_id: ID,
        sale_id:ID,
        operator: address
    }

    struct AdjustPrice<phantom Item,phantom Market>has copy,drop{
        slingshot_id: ID,
        sale_id:ID,
        new_price: u64,
        operator: address
    }

    struct PurchaseEvent<phantom Item,phantom Market> has copy,drop{
        slingshot_id: ID,
        sale_id:ID,
        item_id: ID,
        price: u64,
        operator: address
    }



    public(friend) fun market_create_event<Item,Market>( market_id: ID,
                                                      start_time: u64,
                                                      end_time: u64,
                                                      price: u64,operator: address){
        event::emit(MarketCreateEvent<Item,Market>{
            market_id,
            start_time,
            end_time,
            price,operator
        })
    }


    public(friend) fun remove_sale_event<Item,Market>(slingshot_id: ID,sale_id:ID,operator: address){
        event::emit(RemoveSalesEvent<Item,Market>{
            slingshot_id,
            sale_id,
            operator
        })
    }

    public(friend) fun adjust_price_event<Item,Market>(slingshot_id: ID,sale_id:ID,new_price: u64,operator: address){
        event::emit(AdjustPrice<Item,Market>{
            slingshot_id,
            sale_id,
            new_price,
            operator
        })
    }

    public(friend) fun purchase_event<Item,Market>(slingshot_id: ID,sale_id:ID,item_id:ID,price: u64,operator: address){
        event::emit(PurchaseEvent<Item,Market>{
            slingshot_id,
            sale_id,
            item_id,
            price,
            operator
        })
    }

}
