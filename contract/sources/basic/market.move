// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::market {
    use sui::object::{Self, ID, UID};
    use sui::url::{Self, Url};
    use std::string;
    use swift_nft::tags::{Self, Tags};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_set::{Self, VecSet};
    use sui::dynamic_object_field as ofield;
    use sui::pay;
    use std::vector;
    use swift_nft::market_event;


    struct Listing<phantom Item: store + key> has store, key {
        id: UID,
        price: u64,
        owner: address
    }

    struct Collection<phantom Item> has key, store {
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

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EAmountZero: u64 = 2;
    const EOwnerAuth: u64 = 3;
    const EObjectNotExist: u64 = 4;
    const EAlreadyExistCollectionType: u64 = 5;


    fun init(ctx: &mut TxContext) {
        let market = Marketplace {
            id: object::new(ctx),
            collection: vec_set::empty(),
            balance: coin::zero<SUI>(ctx),
            fee: 150,
        };
        market_event::market_created_event(object::id(&market), tx_context::sender(ctx));

        let profits = WithdrawMarket {
            id: object::new(ctx),
        };

        transfer::share_object(market);
        transfer::transfer(profits, tx_context::sender(ctx));
    }

    public entry fun create_collection<Item>(
        market: &mut Marketplace,
        name: vector<u8>,
        description: vector<u8>,
        tags: vector<vector<u8>>,
        logo_image: vector<u8>,
        featured_image: vector<u8>,
        website: vector<u8>,
        tw: vector<u8>,
        discord: vector<u8>,
        fee: u64,
        ctx: &mut TxContext) {
        let collection = Collection<Item> {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            tags: tags::from_vec_u8(&mut tags),
            logo_image: url::new_unsafe_from_bytes(logo_image),
            featured_image: url::new_unsafe_from_bytes(featured_image),
            website: url::new_unsafe_from_bytes(website),
            tw: url::new_unsafe_from_bytes(tw),
            discord: url::new_unsafe_from_bytes(discord),
            receiver: tx_context::sender(ctx),
            balance: coin::zero<SUI>(ctx),
            fee,
        };
        let collection_id = object::id(&collection);
        market_event::collection_created_event(collection_id, tx_context::sender(ctx));
        vec_set::insert(&mut market.collection, collection_id);
        transfer::share_object(collection);
    }

    public entry fun list<Item: store+key>(collection: &mut Collection<Item>, item: Item,
                                           price: u64, ctx: &mut TxContext) {
        let item_id = object::id(&item);
        let id = object::new(ctx);
        ofield::add(&mut id, true, item);
        let listing = Listing<Item> {
            id,
            price,
            owner: tx_context::sender(ctx),
        };
        let listing_id = object::id(&listing);
        ofield::add(&mut collection.id, item_id, listing);

        market_event::item_list_event(object::id(collection), item_id, listing_id, tx_context::sender(ctx), price);
    }


    public entry fun adjust_price<Item: store+key>(
        collection: &mut Collection<Item>,
        item_id: ID,
        price: u64,
        ctx: &mut TxContext) {
        let collection_id = object::id(collection);
        let listing = ofield::borrow_mut<ID, Listing<Item>>(&mut collection.id, item_id);
        assert!(listing.owner == tx_context::sender(ctx), EOwnerAuth);
        listing.price = price;
        market_event::item_adjust_price_event(collection_id, object::id(listing), tx_context::sender(ctx), price);
    }

    public fun delist<Item: store+key>(collection: &mut Collection<Item>,
                                       item_id: ID,
                                       ctx: &mut TxContext): Item {
        let listing = ofield::remove<ID, Listing<Item>>(&mut collection.id, item_id);
        let listing_id = object::id(&listing);
        let Listing<Item> {
            id,
            price,
            owner,
        } = listing;
        assert!(tx_context::sender(ctx) == owner, ENotOwner);
        let item = ofield::remove<bool, Item>(&mut id, true);
        market_event::item_delisted_event(object::id(collection), item_id, listing_id, tx_context::sender(ctx), price);

        object::delete(id);
        item
    }

    public fun buy<Item: store+key>(market: &mut Marketplace, collection: &mut Collection<Item>,
                                    item_id: ID,
                                    paid: Coin<SUI>, ctx: &mut TxContext): Item {
        let listing = ofield::remove<ID, Listing<Item>>(&mut collection.id, item_id);
        let listing_id = object::id(&listing);
        let Listing<Item> {
            id,
            price,
            owner,
        } = listing;

        assert!(coin::value(&paid) >= price, EAmountIncorrect);

        let market_fee = price * market.fee / 10000;
        let collection_fee = price * collection.fee / 10000;

        let surplus = price - market_fee - collection_fee;

        assert!(surplus > 0, EAmountZero);
        pay::split_and_transfer(&mut paid, surplus, owner, ctx);

        let collection_value = coin::split(&mut paid, collection_fee, ctx);
        let market_value = coin::split(&mut paid, market_fee, ctx);

        coin::join(&mut market.balance, collection_value);
        coin::join(&mut collection.balance, market_value);

        let item = ofield::remove<bool, Item>(&mut id, true);
        market_event::item_puchased_event(object::id(collection), item_id, listing_id, owner, price);

        object::delete(id);
        transfer::transfer(paid, tx_context::sender(ctx));
        item
    }


    public fun buy_script<Item: store+key>(market: &mut Marketplace, collection: &mut Collection<Item>,
                                           item_id: ID,
                                           paid: &mut Coin<SUI>, ctx: &mut TxContext): Item {
        let listing = ofield::remove<ID, Listing<Item>>(&mut collection.id, item_id);
        let listing_id = object::id(&listing);
        let Listing<Item> {
            id,
            price,
            owner,
        } = listing;

        assert!(coin::value(paid) >= price, EAmountIncorrect);

        let market_fee = price * market.fee / 10000;
        let collection_fee = price * collection.fee / 10000;

        let surplus = price - market_fee - collection_fee;

        assert!(surplus > 0, EAmountZero);

        pay::split_and_transfer(paid, surplus, owner, ctx);

        let collection_value = coin::split(paid, collection_fee, ctx);
        let market_value = coin::split(paid, market_fee, ctx);

        coin::join(&mut market.balance, market_value);
        coin::join(&mut collection.balance, collection_value);

        let item = ofield::remove<bool, Item>(&mut id, true);

        market_event::item_puchased_event(object::id(collection), item_id, listing_id, owner, price);

        object::delete(id);
        item
    }

    public entry fun buy_muti_item_script<Item: store+key>(
        market: &mut Marketplace,
        collection: &mut Collection<Item>,
        item_ids: vector<ID>,
        pay_list: vector<Coin<SUI>>,
        ctx: &mut TxContext
    ) {
        let paid = vector::pop_back(&mut pay_list);
        pay::join_vec<SUI>(&mut paid, pay_list);
        while (vector::length(&item_ids) != 0) {
            let ids = vector::pop_back(&mut item_ids);
            buy_and_take_script<Item>(market, collection, ids, &mut paid, ctx);
        };
        transfer::transfer(paid, tx_context::sender(ctx))
    }

    public entry fun buy_and_take_script<Item: store+key>(market: &mut Marketplace, collection: &mut Collection<Item>,
                                                          item_id: ID,
                                                          paid: &mut Coin<SUI>, ctx: &mut TxContext) {
        transfer::transfer(buy_script<Item>(market, collection, item_id, paid, ctx), tx_context::sender(ctx))
    }

    public entry fun buy_and_take<Item: store+key>(market: &mut Marketplace, collection: &mut Collection<Item>,
                                                   item_id: ID,
                                                   paid: Coin<SUI>, ctx: &mut TxContext) {
        transfer::transfer(buy<Item>(market, collection, item_id, paid, ctx), tx_context::sender(ctx))
    }

    public entry fun buy_and_take_mul_coin<Item: store+key>(
        market: &mut Marketplace,
        collection: &mut Collection<Item>,
        item_id: ID,
        pay_list: vector<Coin<SUI>>,
        ctx: &mut TxContext) {
        let paid = vector::pop_back(&mut pay_list);
        pay::join_vec<SUI>(&mut paid, pay_list);
        transfer::transfer(buy<Item>(market, collection, item_id, paid, ctx), tx_context::sender(ctx))
    }

    public fun collect_profit_collection<Item>(collection: &mut Collection<Item>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == collection.receiver, EOwnerAuth);
        let balances = coin::value(&mut collection.balance);
        let coins = coin::split(&mut collection.balance, balances, ctx);
        transfer::transfer(coins, tx_context::sender(ctx));
    }

    public entry fun collect_profits(_owner: &WithdrawMarket, market: &mut Marketplace, ctx: &mut TxContext) {
        let balances = coin::value(&mut market.balance);
        let coins = coin::split(&mut market.balance, balances, ctx);
        transfer::transfer(coins, tx_context::sender(ctx));
    }


    public entry fun delist_take<Item: key + store>(
        collection: &mut Collection<Item>,
        item_id: ID,
        ctx: &mut TxContext) {
        let item = delist<Item>(collection, item_id, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
    }


    public entry fun update_collection_receiver<Item>(
        colection: &mut Collection<Item>,
        owner: address,
        ctx: &mut TxContext
    ) {
        assert!(colection.receiver == tx_context::sender(ctx), ENotOwner);
        colection.receiver = owner
    }

    public entry fun update_collection_fee<Item>(colection: &mut Collection<Item>, fee: u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == colection.receiver, ENotOwner);
        colection.fee = fee
    }

    public entry fun update_collection_tw<Item>(colection: &mut Collection<Item>, tw: vector<u8>, ctx: &mut TxContext) {
        let twitter = url::new_unsafe_from_bytes(tw);
        assert!(tx_context::sender(ctx) == colection.receiver, ENotOwner);
        colection.tw = twitter
    }

    public entry fun update_collection_website<Item>(
        colection: &mut Collection<Item>,
        website: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == colection.receiver, ENotOwner);
        colection.website = url::new_unsafe_from_bytes(website)
    }

    public entry fun update_collection_discord<Item>(
        colection: &mut Collection<Item>,
        discord: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == colection.receiver, ENotOwner);
        colection.discord = url::new_unsafe_from_bytes(discord)
    }

    fun update_market_fee(_owner: &WithdrawMarket, market: &mut Marketplace, fee: u64, _ctx: &mut TxContext) {
        market.fee = fee
    }
}
