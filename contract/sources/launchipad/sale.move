module swift_nft::sale {
    use sui::object::{Self,ID,UID};
    use sui::tx_context::TxContext;
    use std::vector;
    use sui::object_table::{Self,ObjectTable};
    use swift_nft::sale_event;
    //friend  swift_nft::slingshot_market;


    struct Sale<phantom Item: key+store,Market: store>has key,store {
        id: UID,
        nfts: ObjectTable<ID, Item>,
        whitelist: bool,
        market: Market,
    }

    public fun create_empty_sale<Item: key+store,Market: store>(market: Market,ctx: &mut TxContext): Sale<Item,Market>{
        let new_sale= Sale<Item,Market>{
            id: object::new(ctx),
            nfts: object_table::new<ID,Item>(ctx),
            whitelist:false,
            market
        };
        let sale_id=object::id(&new_sale);
        sale_event::create_sale_event<Item,Market>(sale_id,false);
        return new_sale
    }

    public fun create_sale<Item: key+store,Market: store>(nfts: vector<Item> ,whitelist:bool,market: Market,ctx: &mut TxContext): Sale<Item,Market>{
        let new_sale=Sale<Item,Market>{
            id: object::new(ctx),
            nfts: object_table::new<ID,Item>(ctx),
            whitelist,
            market
        };
        let sale_id=object::id(&new_sale);
        sale_event::create_sale_event<Item,Market>(sale_id,whitelist);

        list_muti_item(&mut new_sale,nfts);

        return new_sale
    }

    //public(friend)
    public fun list_muti_item<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>,nfts: vector<Item>){
        let sale_id=object::id(sales);
        let length=vector::length(&nfts);
        let ids=vector::empty<ID>();
        let i=0;
        while ( i < length ){
            let item=vector::pop_back(&mut nfts);
            let  nft_id=object::id(&item);
            vector::push_back(&mut ids,nft_id);
            object_table::add(&mut sales.nfts,nft_id,item);
            i=i+1;
        };
        sale_event::list_item_event<Item,Market>(sale_id,ids);
        vector::destroy_empty(nfts);
    }


    public  fun list_item<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>,nft: Item){

        let  nft_id=object::id(&nft);
        object_table::add(&mut sales.nfts,nft_id,nft);
        sale_event::list_item_event<Item,Market>(object::id(sales),vector::singleton(nft_id))

    }
    public  fun withdraw<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>,nft_id: ID):Item {
        let sale_id=object::id(sales);

        let item=object_table::remove(&mut sales.nfts,nft_id);

        sale_event::withdraw_item_event<Item,Market>(sale_id,nft_id);

        return item
    }

    public  fun unlist_item<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>,nfts: vector<ID>): vector<Item>{
        let sale_id=object::id(sales);
        let length=vector::length(&nfts);
        let item_result=vector::empty<Item>();
        let i=0;
        while ( i < length ){
            let item_id=vector::pop_back(&mut nfts);

            let item=object_table::remove(&mut sales.nfts,item_id);
            vector::push_back(&mut item_result,item);
            i=i+1;
        };
        sale_event::unlist_item_event<Item,Market>(sale_id,nfts);
        return item_result
    }


    public fun whitelist_on<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>){
        sales.whitelist=true;
        sale_event::modity_whitelist_event<Item,Market>(object::id(sales),true)
    }

    public  fun whitelist_off<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>){
        sales.whitelist=false;
        sale_event::modity_whitelist_event<Item,Market>(object::id(sales),false)
    }

    public fun whitelist_status<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>): bool{
        return sales.whitelist
    }

    public fun get_mut_market<Item: key+store,Market: store>(sales :&mut Sale<Item,Market>): &mut Market{
        return  &mut sales.market
    }

    public fun get_market<Item: key+store,Market: store>(sales :&Sale<Item,Market>): & Market{
        return  &sales.market
    }




}
