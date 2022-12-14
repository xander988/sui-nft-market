module swift_nft::market {
    use sui::object::{Self,ID,UID};
    use sui::url::{Self,Url};
    use std::string;
    use swift_nft::tags::{Self,Tags};
    use sui::sui::SUI;
    use sui::coin::{Self,Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_set::{Self,VecSet};
    use sui::event;
    use sui::dynamic_object_field as ofield;
    use sui::pay;
    use std::vector;


    struct CreateMarketEvent has copy,drop{
        market_id: ID,
        owner: address,
    }
    struct InitCollectionEvent has copy,drop{
        collection_id: ID,
        create_address: address
    }

    struct ListingEvent has copy, drop {
        collection_id: ID,
        item_id: ID,
        listing_id: ID,
        price: u64,
        seller: address
    }

    struct BuyEvent has copy, drop {
        collection_id: ID,
        item_id: ID,
        listing_id: ID,
        price: u64,
        seller: address
    }
    struct DeListEvent has copy, drop {
        collection_id: ID,
        item_id: ID,
        listing_id: ID,
        price: u64,
        owner: address
    }

    struct AdjustPriceEvent has copy,drop{
        collection_id: ID,
        listing_id: ID,
        owner: address,
        price: u64,
    }

    struct Listing<phantom T: store + key> has store, key {
        id: UID,
        price: u64,
        owner: address
    }

    struct Collection<phantom T> has key,store {
        id: UID,
        name: string::String,
        description: string::String,
        tags: Tags,
        logo_image: Url,
        featured_image: Url,
        website: Url,
        tw: Url,
        discord: Url,
        receiver: address,
        balance: Coin<SUI>,
        fee: u64
    }
    struct Marketplace has key {
        id: UID,
        collection: VecSet<ID>,
        balance: Coin<SUI>,
        fee: u64,
    }

    struct WithdrawMarket has key {
        id: UID,
    }

    const EAmountIncorrect :u64=0;
    const ENotOwner: u64=1;
    const EAmountZero: u64=2;
    const EOwnerAuth: u64=3;
    const EObjectNotExist: u64=4;
    const EAlreadyExistCollectionType: u64=5;


    fun init(ctx: &mut TxContext){
        let market=Marketplace{
            id:object::new(ctx),
            collection: vec_set::empty(),
            balance:coin::zero<SUI>(ctx),
            fee:150,
        };
        event::emit(
            CreateMarketEvent{
                market_id: object::id(&market),
                owner: tx_context::sender(ctx),
            }
        );
        let profits=WithdrawMarket{
            id:object::new(ctx),
        };

        transfer::share_object(market);
        transfer::transfer(profits,tx_context::sender(ctx));
    }

    public entry  fun create_collection<T>(
        market:  &mut Marketplace,
        name: vector<u8>,
        description: vector<u8>,
        tags: vector<vector<u8>>,
        logo_image: vector<u8>,
        featured_image: vector<u8>,
        website: vector<u8>,
        tw: vector<u8>,
        discord: vector<u8>,
        fee: u64,
        ctx: &mut TxContext){
        let collection=Collection<T>{
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            tags: tags::from_vec_u8(&mut tags),
            logo_image: url::new_unsafe_from_bytes(logo_image),
            featured_image: url::new_unsafe_from_bytes(featured_image),
            website:url::new_unsafe_from_bytes(website),
            tw: url::new_unsafe_from_bytes(tw),
            discord: url::new_unsafe_from_bytes(discord),
            receiver: tx_context::sender(ctx),
            balance: coin::zero<SUI>(ctx),
            fee,
        };
        let collection_id=object::id(&collection);
        event::emit(InitCollectionEvent{
            collection_id,
            create_address: tx_context::sender(ctx),
        });
        vec_set::insert(&mut market.collection,collection_id);
        transfer::share_object(collection);
    }
    public entry fun  list<T: store+key>(collection: &mut Collection<T>,item: T,
                                         price: u64,ctx: &mut TxContext){
        let item_id=object::id(&item);
        let id=object::new(ctx);
        ofield::add(&mut id,true,item);
        let listing = Listing<T> {
            id,
            price,
            owner: tx_context::sender(ctx),
        };
        let listing_id=object::id(&listing);
        ofield::add(&mut collection.id, item_id, listing);

        event::emit(ListingEvent{
            collection_id: object::id(collection),
            item_id,
            listing_id,
            price,
            seller: tx_context::sender(ctx)
        });
    }


    public entry fun adjust_price<T: store+key>(
        collection: &mut Collection<T>,
        item_id: ID,
        price: u64,
        ctx: &mut TxContext){
        let collection_id = object::id(collection);
        let listing=ofield::borrow_mut<ID,Listing<T>>(&mut collection.id,item_id);
        assert!(listing.owner==tx_context::sender(ctx),EOwnerAuth);
        listing.price=price;
        event::emit(AdjustPriceEvent{
            collection_id,
            listing_id: object::id(listing),
            owner: tx_context::sender(ctx),
            price,
        });
    }

    public fun delist<T: store+key>(collection: &mut Collection<T>,
                                    item_id: ID ,
                                    ctx: &mut TxContext): T{
        let listing=ofield::remove<ID,Listing<T>>(&mut collection.id,item_id);
        let listing_id=object::id(&listing);
        let Listing<T>{
            id,
            price,
            owner,
        }=listing;
        assert!(tx_context::sender(ctx)==owner,ENotOwner);
        let item= ofield::remove<bool,T>(&mut id,true);
        event::emit(DeListEvent{
            collection_id: object::id(collection),
            item_id,
            listing_id,
            price,
            owner: tx_context::sender(ctx),
        });
        object::delete(id);
        item
    }

    public fun  buy<T: store+key>(market:  &mut Marketplace,collection: &mut Collection<T>,
                                  item_id: ID,
                                  paid: Coin<SUI>,ctx: &mut TxContext): T{

        let listing=ofield::remove<ID,Listing<T>>(&mut collection.id,item_id);
        let listing_id=object::id(&listing);
        let Listing<T>{
            id,
            price,
            owner,
        }=listing;

        assert!(coin::value(&paid)>=price, EAmountIncorrect);

        let market_fee=price*market.fee/10000;
        let collection_fee=price*collection.fee/10000;

        let surplus=price-market_fee-collection_fee;

        assert!(surplus>0,EAmountZero);
        pay::split_and_transfer(&mut paid,surplus,owner,ctx);

        let collection_value=coin::split(&mut paid,collection_fee,ctx);
        let market_value=coin::split(&mut paid,market_fee,ctx);

        coin::join(&mut market.balance,collection_value);
        coin::join(&mut collection.balance,market_value);

        let item =ofield::remove<bool,T>(&mut id,true);
        event::emit(BuyEvent{
            collection_id: object::id(collection),
            item_id,
            listing_id,
            price,
            seller: owner,
        });
        object::delete(id);
        transfer::transfer(paid,tx_context::sender(ctx));
        item
    }



    public fun  buy_script<T: store+key>(market:  &mut Marketplace,collection: &mut Collection<T>,
                                  item_id: ID,
                                  paid: &mut Coin<SUI>,ctx: &mut TxContext): T{
        let listing=ofield::remove<ID,Listing<T>>(&mut collection.id,item_id);
        let listing_id=object::id(&listing);
        let Listing<T>{
            id,
            price,
            owner,
        }=listing;

        assert!(coin::value(paid)>=price, EAmountIncorrect);

        let market_fee=price*market.fee/10000;
        let collection_fee=price*collection.fee/10000;

        let surplus=price-market_fee-collection_fee;

        assert!(surplus>0,EAmountZero);

        pay::split_and_transfer(paid,surplus,owner,ctx);

        let collection_value=coin::split(paid,collection_fee,ctx);
        let market_value=coin::split(paid,market_fee,ctx);

        coin::join(&mut market.balance,market_value);
        coin::join(&mut collection.balance,collection_value);

        let item =ofield::remove<bool,T>(&mut id,true);
        event::emit(BuyEvent{
            collection_id: object::id(collection),
            item_id,
            listing_id,
            price,
            seller: owner,
        });

        object::delete(id);
        item
    }

    public entry fun buy_muti_item_script<T1: store+key>(market:  &mut Marketplace,collection: &mut Collection<T1>,
                                                    item_ids: vector<ID>, pay_list: vector<Coin<SUI>>,ctx: &mut TxContext){
        let paid=vector::pop_back(&mut pay_list);
        pay::join_vec<SUI>(&mut paid,pay_list);
        while (vector::length(&item_ids)!=0){
            let ids=vector::pop_back(&mut item_ids);
            buy_and_take_script<T1>(market,collection,ids,&mut paid,ctx);
        };
        transfer::transfer(paid,tx_context::sender(ctx))
    }
    public entry fun buy_and_take_script<T1: store+key>(market:  &mut Marketplace,collection: &mut Collection<T1>,
                                                 item_id: ID,
                                                 paid: &mut Coin<SUI>,ctx: &mut TxContext){
        transfer::transfer(buy_script<T1>(market,collection,  item_id, paid,ctx), tx_context::sender(ctx))
    }

    public entry fun buy_and_take<T1: store+key>(market:  &mut Marketplace,collection: &mut Collection<T1>,
                                                 item_id: ID,
                                                 paid: Coin<SUI>,ctx: &mut TxContext){
        transfer::transfer(buy<T1>(market,collection,  item_id,paid,ctx), tx_context::sender(ctx))
    }
    public entry fun buy_and_take_mul_coin<T1: store+key>(
        market:  &mut Marketplace,
        collection: &mut Collection<T1>,
        item_id: ID,
        pay_list: vector<Coin<SUI>>,
        ctx: &mut TxContext){

        let paid=vector::pop_back(&mut pay_list);
        pay::join_vec<SUI>(&mut paid,pay_list);
        transfer::transfer(buy<T1>(market,collection,  item_id,paid,ctx), tx_context::sender(ctx))
    }

    public fun collect_profit_collection<T1>(collection: &mut Collection<T1>,ctx: &mut TxContext){
        assert!(tx_context::sender(ctx)==collection.receiver,EOwnerAuth);
        let balances=coin::value(&mut collection.balance);
        let coins=coin::split(&mut collection.balance,balances,ctx);
        transfer::transfer(coins,tx_context::sender(ctx));
    }

    public entry fun collect_profits(_owner: &WithdrawMarket,market:  &mut Marketplace,ctx: &mut TxContext){
        let balances=coin::value(&mut market.balance);
        let coins=coin::split(&mut market.balance,balances,ctx);
        transfer::transfer(coins,tx_context::sender(ctx));
    }


    public entry fun delist_take<T1: key + store>(
        collection:  &mut Collection<T1>,
        item_id: ID,
        ctx: &mut TxContext){
        let item = delist<T1>(collection, item_id, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
    }


    public entry fun update_collection_receiver<T1>(colection: &mut Collection<T1>, owner: address,ctx: &mut TxContext){
        assert!(colection.receiver==tx_context::sender(ctx),ENotOwner);
        colection.receiver=owner

    }
    public entry fun update_collection_fee<T1>(colection: &mut Collection<T1>, fee: u64,ctx: &mut TxContext){
        assert!(tx_context::sender(ctx)==colection.receiver,ENotOwner);
        colection.fee=fee
    }
    public entry fun update_collection_tw<T1>(colection: &mut Collection<T1>, tw: vector<u8>,ctx: &mut TxContext){
        let twitter=url::new_unsafe_from_bytes(tw);
        assert!(tx_context::sender(ctx)==colection.receiver,ENotOwner);
        colection.tw=twitter
    }
    public entry fun update_collection_website<T1>(colection: &mut Collection<T1>, website: vector<u8>,ctx: &mut TxContext){
        assert!(tx_context::sender(ctx)==colection.receiver,ENotOwner);
        colection.website=url::new_unsafe_from_bytes(website)
    }
    public entry fun update_collection_discord<T1>(colection: &mut Collection<T1>, discord: vector<u8>,ctx: &mut TxContext){
        assert!(tx_context::sender(ctx)==colection.receiver,ENotOwner);
        colection.discord=url::new_unsafe_from_bytes(discord)
    }

    fun update_market_fee(_owner: &WithdrawMarket,market: &mut Marketplace,fee: u64,_ctx: &mut TxContext){
        market.fee=fee
    }

}
