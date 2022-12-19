// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::slingshot_market {

    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use swift_nft::sale::{Self, Sale};
    use std::vector;
    use swift_nft::slingshot::{Self, Slingshot};
    use sui::tx_context;
    use sui::transfer;
    use std::option::{Self, Option};
    use sui::pay;
    use swift_nft::whitelist::{Self, WhiteListToken};
    use swift_nft::slingshot_market_event;

    const EMarketSaleAlreadyStart: u64 = 0;

    const ESalesFundsInsufficient: u64 = 1;

    const ESTwoalesMisMatch: u64 = 2;

    struct SlingshotMarket<phantom Item, phantom CoinType>has key, store {
        id: UID,
        start_time: u64,
        end_time: u64,
        price: u64,
        balance: Option<Coin<CoinType>>
    }

    public entry fun create<Item: key+store, CoinType>(
        collection: ID,
        admin: address,
        live: bool,
        whitelists: vector<bool>,
        nft_num: vector<u64>,
        nft_vec: vector<Item>,
        start_times: vector<u64>,
        end_times: vector<u64>,
        prices: vector<u64>,
        ctx: &mut TxContext) {
        let array = vector::empty<vector<Item>>();
        let length = vector::length(&nft_num);
        let i = 0;
        while (i < length) {
            let j = 0;
            let tmp_item = vector::empty<Item>();
            let num = vector::pop_back(&mut nft_num);
            while (j < num) {
                let item = vector::pop_back(&mut nft_vec);
                vector::push_back(&mut tmp_item, item);
                j = j + 1
            };
            vector::push_back(&mut array, tmp_item);
        };
        vector::reverse(&mut array);
        vector::destroy_empty(nft_vec);
        create_muti_sales_market<Item, CoinType>(
            collection,
            admin,
            live,
            whitelists,
            array,
            start_times,
            end_times,
            prices,
            ctx
        )
    }

    public fun create_muti_sales_market<Item: key+store, CoinType>(
        collection: ID,
        admin: address,
        live: bool,
        whitelists: vector<bool>,
        nft_vec: vector<vector<Item>>,
        start_times: vector<u64>,
        end_times: vector<u64>,
        prices: vector<u64>,
        ctx: &mut TxContext
    ) {
        let length = vector::length(&nft_vec);
        let result = vector::empty<Sale<Item, SlingshotMarket<Item, CoinType>>>();
        let i = 0;
        while (i < length) {
            let start_time = vector::pop_back(&mut start_times);
            let end_time = vector::pop_back(&mut end_times);
            let price = vector::pop_back(&mut prices);
            let nfts = vector::pop_back(&mut nft_vec);
            let whitelist = vector::pop_back(&mut whitelists);
            let market = SlingshotMarket<Item, CoinType> {
                id: object::new(ctx),
                start_time,
                end_time,
                price,
                balance: option::none(),
            };
            slingshot_market_event::market_created_event<Item, SlingshotMarket<Item, CoinType>>(
                object::id(&market),
                start_time,
                end_time,
                price,
                tx_context::sender(ctx)
            );
            let new_sale = sale::create_sale<Item, SlingshotMarket<Item, CoinType>>(nfts, whitelist, market, ctx);
            vector::push_back(&mut result, new_sale);
            i = i + 1
        };
        vector::destroy_empty(nft_vec);
        slingshot::create_slingshot<Item, SlingshotMarket<Item, CoinType>>(collection, admin, live, result, ctx);
    }

    public entry fun create_market<Item: key+store, CoinType>(
        collection: ID,
        admin: address,
        live: bool,
        nfts: vector<Item>,
        whitelist: bool,
        start_time: u64,
        end_time: u64,
        price: u64,
        ctx: &mut TxContext
    ) {
        let market = SlingshotMarket<Item, CoinType> {
            id: object::new(ctx),
            start_time,
            end_time,
            price,
            balance: option::none(),
        };
        slingshot_market_event::market_created_event<Item, SlingshotMarket<Item, CoinType>>(
            object::id(&market),
            start_time,
            end_time,
            price,
            tx_context::sender(ctx)
        );
        let new_sale = sale::create_sale<Item, SlingshotMarket<Item, CoinType>>(nfts, whitelist, market, ctx);
        let v = vector::empty<Sale<Item, SlingshotMarket<Item, CoinType>>>();
        vector::push_back(&mut v, new_sale);
        slingshot::create_slingshot<Item, SlingshotMarket<Item, CoinType>>(collection, admin, live, v, ctx);
    }

    public fun remove_sale<Item: key+store, CoinType>(
        sling: &mut Slingshot<Item, SlingshotMarket<Item, CoinType>>,
        sale_id: ID,
        ctx: &mut TxContext
    ) {
        let borrow_mut_sale = slingshot::borrow_mut_sales(sling, sale_id, ctx);
        let mut_market = sale::get_mut_market<Item, SlingshotMarket<Item, CoinType>>(borrow_mut_sale);
        assert!(mut_market.start_time > tx_context::epoch(ctx), EMarketSaleAlreadyStart);
        let sale = slingshot::remove_sales(sling, sale_id);
        slingshot_market_event::sale_remove_event<Item, SlingshotMarket<Item, CoinType>>(
            object::id(sling),
            sale_id,
            tx_context::sender(ctx)
        );
        transfer::transfer(sale, tx_context::sender(ctx));
    }

    public entry fun adjust_price<Item: key+store, CoinType>(
        slingshot: &mut Slingshot<Item, SlingshotMarket<Item, CoinType>>,
        sale_id: ID,
        price: u64,
        ctx: &mut TxContext
    ) {
        let borrow_sale = slingshot::borrow_sales(slingshot, sale_id, ctx);
        let market = sale::get_market(borrow_sale);
        assert!(market.start_time > tx_context::epoch(ctx), EMarketSaleAlreadyStart);
        let borrow_mut_sale = slingshot::borrow_mut_sales(slingshot, sale_id, ctx);
        let mut_market = sale::get_mut_market<Item, SlingshotMarket<Item, CoinType>>(borrow_mut_sale);

        //assert!(mut_market.start_time>tx_context::epoch(ctx),EMarketSaleAlreadyStart);
        mut_market.price = price;
        slingshot_market_event::item_adjust_price_event<Item, SlingshotMarket<Item, CoinType>>(
            object::id(slingshot),
            sale_id,
            price,
            tx_context::sender(ctx)
        )
    }

    public fun collect<Item: key+store, CoinType>(
        slingshot: &mut Slingshot<Item, SlingshotMarket<Item, CoinType>>,
        sale_id: ID,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let borrow_mut_sale = slingshot::borrow_mut_sales(slingshot, sale_id, ctx);
        let funds = &mut sale::get_mut_market<Item, SlingshotMarket<Item, CoinType>>(borrow_mut_sale).balance;
        let money = option::extract(funds);
        transfer::transfer(money, receiver)
    }

    public entry fun purchase<Item: key+store, CoinType>(
        slingshot: &mut Slingshot<Item, SlingshotMarket<Item, CoinType>>,
        sale_id: ID,
        item_id: ID,
        buyer_funds: &mut  Coin<CoinType>,
        ctx: &mut TxContext
    ) {
        let borrow_sale = slingshot::borrow_sales(slingshot, sale_id, ctx);
        let price = sale::get_market<Item, SlingshotMarket<Item, CoinType>>(borrow_sale).price;
        assert!(coin::value(buyer_funds) >= price, ESalesFundsInsufficient);
        let fund = coin::split(buyer_funds, price, ctx);
        let borrow_mut_sale = slingshot::borrow_mut_sales(slingshot, sale_id, ctx);
        let item = sale::withdraw(borrow_mut_sale, item_id);
        let market_coin = &mut sale::get_mut_market<Item, SlingshotMarket<Item, CoinType>>(borrow_mut_sale).balance;
        let funds = option::borrow_mut(market_coin);
        pay::join(funds, fund);
        slingshot_market_event::item_purchased_event<Item, SlingshotMarket<Item, CoinType>>(
            object::id(slingshot),
            sale_id,
            item_id,
            price,
            tx_context::sender(ctx)
        );
        transfer::transfer(item, tx_context::sender(ctx));
    }

    public entry fun purchase_via_whitelist<Item: key+store, CoinType>(
        slingshot: &mut Slingshot<Item, SlingshotMarket<Item, CoinType>>,
        sale_id: ID,
        wl: WhiteListToken<Item, SlingshotMarket<Item, CoinType>>,
        item_id: ID,
        buyer_funds: &mut  Coin<CoinType>,
        ctx: &mut TxContext
    ) {
        assert!(sale_id == whitelist::get_wl_sale_id(&wl), ESTwoalesMisMatch);
        purchase(slingshot, sale_id, item_id, buyer_funds, ctx);
        whitelist::destory(wl, ctx);
    }
}
