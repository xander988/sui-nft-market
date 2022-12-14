module swift_nft::wl_event {
    use sui::object::ID;
    use sui::event;
    friend  swift_nft::whitelist ;

    struct ActivityCreateEvent<phantom Item,phantom Market>has copy,drop{
        activity_id: ID,
        sale_id: ID,
    }

    struct WhiteListCreateEvent<phantom Item,phantom Market>has copy,drop{
        white_list: ID,
        creator: address,
    }

    struct WhiteListDestoryEvent<phantom Item,phantom Market>has copy,drop{
        white_list: ID,
        creator: address,
    }

    public(friend) fun activity_create_event<Item,Market>(activity_id: ID,
                                                          sale_id: ID){
        event::emit(ActivityCreateEvent<Item,Market>{
            activity_id,
            sale_id
        })
    }

    public(friend) fun whitelist_create_event<Item,Market>( white_list: ID,
                                                            creator: address,){
        event::emit(WhiteListCreateEvent<Item,Market>{
            white_list,
            creator
        })
    }

    public(friend) fun whitelist_destory_event<Item,Market>( white_list: ID,
                                                            creator: address,){
        event::emit(WhiteListDestoryEvent<Item,Market>{
            white_list,
            creator
        })
    }



}
