module swift_nft::slingshot_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::slingshot;

    struct CreateSlingshotEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }

    struct AddSalesEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }

    struct RemoveSalesEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        sales: vector<ID>
    }
    struct ModityLiveEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        status: bool
    }

    struct UpdateAdminEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        admin: address,
    }

    struct BorrowSalesEvent<phantom Item, phantom Market> has copy, drop {
        slingshot_id: ID,
        operator: address,
    }

    public(friend)  fun create_slingshot_event<Item,Market>(slingshot_id: ID,
                                                            sales: vector<ID>){
        event::emit(CreateSlingshotEvent<Item,Market>{
            slingshot_id,
            sales
        })

    }


    public(friend)  fun add_sales_event<Item,Market>(slingshot_id: ID,
                                                            sales: vector<ID>){
        event::emit(AddSalesEvent<Item,Market>{
            slingshot_id,
            sales
        })
    }

    public(friend)  fun remove_sales_event<Item,Market>(slingshot_id: ID,
                                                     sales: vector<ID>){
        event::emit(RemoveSalesEvent<Item,Market>{
            slingshot_id,
            sales
        })
    }

    public(friend)  fun modity_live_event<Item,Market>(slingshot_id: ID,status: bool){
        event::emit(ModityLiveEvent<Item,Market>{
            slingshot_id,
            status
        })
    }

    public(friend)  fun update_admin_event<Item,Market>(slingshot_id: ID,admin: address){
        event::emit(UpdateAdminEvent<Item,Market>{
            slingshot_id,
            admin
        })
    }


    public(friend)  fun borrow_sales_event<Item,Market>(slingshot_id: ID,operator: address){
        event::emit(BorrowSalesEvent<Item,Market>{
            slingshot_id,
            operator
        })
    }







}
