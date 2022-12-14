module swift_nft::slingshot {

    use sui::object::{Self,UID,ID};
    use sui::object_table::{Self,ObjectTable};
    use swift_nft::sale::Sale;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::vector;
    use sui::tx_context;
    use swift_nft::slingshot_event;
    friend  swift_nft::slingshot_market;


    struct Slingshot<phantom Item: key+store, Market: store> has key, store{
        id: UID,
        collection_id: ID,
        admin: address,
        live: bool,
        sales: ObjectTable<ID,Sale<Item,Market>>
    }

    const EOperateNotAuth: u64=0;


    public fun create_slingshot<Item: key+store,Market: store>(collection_id: ID, admin: address,live: bool,sales:vector<Sale<Item,Market>>,ctx: &mut TxContext){
        let slingshot=Slingshot<Item,Market>{
            id: object::new(ctx),
            collection_id,
            admin,
            live,
            sales:object_table::new(ctx),
        };
        let slingshot_id=object::id(&slingshot);

        let length=vector::length(&sales);
        let sale_ids=vector::empty<ID>();
        let i=0;
        while ( i < length ){
           let pop_sales= vector::pop_back(&mut sales);
            let sale_id=object::id(&pop_sales);
            vector::push_back(&mut sale_ids,sale_id);
            object_table::add(&mut slingshot.sales,sale_id,pop_sales);
            i=i+1
        };
        slingshot_event::create_slingshot_event<Item,Market>(slingshot_id,sale_ids);

        vector::destroy_empty(sales);
        transfer::share_object(slingshot);
    }
    public  fun add_muti_sales<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,sales: vector<Sale<Item,Market>>,ctx: &mut TxContext){
        assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
        let length=vector::length(&sales);
        let sale_vec=vector::empty<ID>();

        let i=0;
        while ( i < length ){
            let pop_sales= vector::pop_back(&mut sales);
            let sale_id=object::id(&pop_sales);
            vector::push_back(&mut sale_vec,sale_id);
            object_table::add(&mut slingshot.sales,sale_id,pop_sales);
            i=i+1
        };
        slingshot_event::add_sales_event<Item,Market>(object::id(slingshot),sale_vec);
        vector::destroy_empty(sales);
    }

    public fun remove_muti_sales<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,sales: vector<ID>,ctx: &mut TxContext): vector<Sale<Item,Market>> {
        assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
        let length = vector::length(&sales);
        let result_sale = vector::empty<Sale<Item, Market>>();
        let i=0;
        while ( i < length ){
            let sale_id = vector::pop_back(&mut sales);
            let remove_sale = object_table::remove(&mut slingshot.sales, sale_id);
            vector::push_back(&mut result_sale, remove_sale);
            i=i+1
        };
        slingshot_event::remove_sales_event<Item,Market>(object::id(slingshot),sales);
        result_sale
    }


    public(friend) fun remove_sales<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,sale_id: ID): Sale<Item,Market>{
        slingshot_event::remove_sales_event<Item,Market>(object::id(slingshot),vector::singleton(sale_id));
        object_table::remove(&mut slingshot.sales, sale_id)
    }

    public  fun borrow_mut_sales<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,sales_id: ID,ctx: &mut TxContext): &mut Sale<Item,Market>{
       assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
       slingshot_event::borrow_sales_event<Item,Market>(object::id(slingshot),tx_context::sender(ctx));

        object_table::borrow_mut(&mut slingshot.sales,sales_id)
    }

    public  fun borrow_sales<Item: key+store,Market: store>(slingshot: &Slingshot<Item,Market>,sales_id: ID,ctx: &mut TxContext): &Sale<Item,Market>{
        assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
        slingshot_event::borrow_sales_event<Item,Market>(object::id(slingshot),tx_context::sender(ctx));
        object_table::borrow(&slingshot.sales,sales_id)
    }

    public fun update_admin<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,admin: address,ctx: &mut TxContext){
        assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
        slingshot_event::update_admin_event<Item,Market>(object::id(slingshot),admin);
        slingshot.admin=admin
    }

    public fun modity_status<Item: key+store,Market: store>(slingshot: &mut Slingshot<Item,Market>,status: bool,ctx: &mut TxContext){
        assert!(slingshot.admin==tx_context::sender(ctx),EOperateNotAuth);
        slingshot_event::modity_live_event<Item,Market>(object::id(slingshot),status);
        slingshot.live=status
    }




}


