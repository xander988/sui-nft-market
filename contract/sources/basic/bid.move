// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::bid {
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::dynamic_object_field as ofield;
    use swift_nft::market::{Self, Collection};
    use swift_nft::bid_event;

    struct BidKey has key, store {
        id: UID,
        item_id: ID,
        bider: address,
    }

    struct ItemBidInfo<phantom CoinType> has key, store {
        id: UID,
        funds: Coin<CoinType>,
        deadline: u64,
    }


    const EBidObjectMismatch: u64 = 0;
    const ECoinType: u64 = 1;
    const ETimeLocking: u64 = 2;
    const ETwoObjectMismatch: u64 = 3;
    const ENoAuth: u64 = 4;
    const EObjectNoExist: u64 = 5;


    public entry fun bid<CoinType>(item_id: ID, funds: Coin<CoinType>, deadline: u64, ctx: &mut TxContext) {
        bid_event::item_bid_event(item_id, tx_context::sender(ctx), coin::value(&funds));
        let bidkey = BidKey {
            id: object::new(ctx),
            item_id,
            bider: tx_context::sender(ctx),
        };
        let item_info = ItemBidInfo<CoinType> {
            id: object::new(ctx),
            funds,
            deadline,
        };
        ofield::add(&mut bidkey.id, item_id, item_info);
        transfer::share_object(bidkey);
    }

    public entry fun deal_list<Item: key+store, CoinType>(
        collection: &mut Collection<Item>,
        items: ID,
        bid_key: &mut BidKey,
        ctx: &mut  TxContext
    ) {
        let items = market::delist(collection, items, ctx);
        deal_unlist<Item, CoinType>(items, bid_key, ctx)
    }

    public entry fun deal_unlist<Item: key+store, CoinType>(items: Item, bid_key: &mut BidKey, ctx: &mut  TxContext) {
        let items_id = object::id(&items);
        assert!(items_id == bid_key.item_id, EBidObjectMismatch);
        let bid_id = object::id(bid_key);
        assert!(ofield::exists_(&mut bid_key.id, items_id), EObjectNoExist);
        let item_info = ofield::remove<ID, ItemBidInfo<CoinType>>(&mut bid_key.id, items_id);
        let ItemBidInfo<CoinType> {
            id,
            funds,
            deadline: _,
        } = item_info;

        let amount_num = coin::value(&funds);

        bid_event::bid_complete_event(object::id(&items), bid_id, true, tx_context::sender(ctx), amount_num);

        transfer::transfer(items, bid_key.bider);
        transfer::transfer(funds, tx_context::sender(ctx));
        object::delete(id)
    }

    public entry fun bid_cancel<CoinType>(bid: &mut BidKey, item_id: ID, ctx: &mut TxContext) {
        assert!(bid.bider == tx_context::sender(ctx), ENoAuth);
        assert!(ofield::exists_(&mut bid.id, item_id), EObjectNoExist);
        let item_info = ofield::remove<ID, ItemBidInfo<CoinType>>(&mut bid.id, item_id);
        let bid_id = object::id(bid);
        let ItemBidInfo<CoinType> {
            id,
            funds,
            deadline: _,
        } = item_info;

        bid_event::bid_cancel_event(item_id, bid_id, tx_context::sender(ctx));

        transfer::transfer(funds, bid.bider);

        object::delete(id)
    }
}