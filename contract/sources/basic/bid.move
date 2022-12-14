module swift_nft::bid {
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};

    use sui::event;
    use sui::transfer;
    use sui::dynamic_object_field as ofield;
    use swift_nft::market::{Self, Collection};

    struct BidEvent has copy, drop {
        item_id: ID,
        bider: address,
        amount: u64,
    }

    struct BidKey has key, store {
        id: UID,
        item_id: ID,
        bider: address,
    }

    struct BidAmount<phantom T> has key, store {
        id: UID,
        money: Coin<T>,
        deadline: u64,
    }

    struct DealEvent has copy, drop {
        item_id: ID,
        bid_id: ID,
        amount: u64,
        success: bool,
        operator: address
    }

    struct CancelEvent has copy, drop {
        item_id: ID,
        bid_id: ID,
        operator: address,
    }

    struct UnlockBidEvent has copy, drop {
        bid_id: ID,
        success: bool,
        operator: address,
    }


    const EBidObjectMismatch: u64 = 0;
    const ECoinType: u64 = 1;
    const ETimeLocking: u64 = 2;
    const ETwoObjectMismatch: u64 = 3;
    const ENoAuth: u64 = 4;
    const EObjectNoExist: u64 = 5;


    public entry fun Bid<T>(item_id: ID, money: Coin<T>, deadline: u64, ctx: &mut TxContext) {
        event::emit(BidEvent {
            item_id,
            bider: tx_context::sender(ctx),
            amount: coin::value(&money),
        });
        let bidkey = BidKey {
            id: object::new(ctx),
            item_id,
            bider: tx_context::sender(ctx),
        };
        let bidamount = BidAmount<T> {
            id: object::new(ctx),
            money,
            deadline,
        };
        ofield::add(&mut bidkey.id, item_id, bidamount);
        transfer::share_object(bidkey);
    }

    public entry fun deal_list<T1: key+store, T2>(
        collection: &mut Collection<T1>,
        items: ID,
        bid_key: &mut BidKey,
        ctx: &mut  TxContext
    ) {
        let items = market::delist(collection, items, ctx);
        deal_unlist<T1, T2>(items, bid_key, ctx)
    }

    public entry fun deal_unlist<T1: key+store, T2>(items: T1, bid_key: &mut BidKey, ctx: &mut  TxContext) {
        let items_id = object::id(&items);
        assert!(items_id == bid_key.item_id, EBidObjectMismatch);
        let bid_id = object::id(bid_key);
        assert!(ofield::exists_(&mut bid_key.id, items_id), EObjectNoExist);
        let bidAmount = ofield::remove<ID, BidAmount<T2>>(&mut bid_key.id, items_id);
        let BidAmount<T2> {
            id,
            money,
            deadline: _,
        } = bidAmount;

        let amount_num = coin::value(&money);

        event::emit(
            DealEvent {
                item_id: object::id(&items),
                bid_id,
                amount: amount_num,
                success: true,
                operator: tx_context::sender(ctx)
            }
        );
        transfer::transfer(items, bid_key.bider);
        transfer::transfer(money, tx_context::sender(ctx));
        object::delete(id)
    }

    public entry fun cancel<T>(bid: &mut BidKey, item_id: ID, ctx: &mut TxContext) {
        assert!(bid.bider == tx_context::sender(ctx), ENoAuth);
        assert!(ofield::exists_(&mut bid.id, item_id), EObjectNoExist);
        let bidAmount = ofield::remove<ID, BidAmount<T>>(&mut bid.id, item_id);
        let bid_id = object::id(bid);
        let BidAmount<T> {
            id,
            money,
            deadline: _,
        } = bidAmount;

        event::emit(
            CancelEvent {
                item_id,
                bid_id,
                operator: tx_context::sender(ctx)
            }
        );
        transfer::transfer(money, bid.bider);

        object::delete(id)
    }
}