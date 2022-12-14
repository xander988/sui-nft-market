module swift_nft::auction{
    use sui::coin::{Self,Coin};
    use sui::object::{Self,UID,ID};
    use std::option::{Self,Option};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;
    use sui::event;
    use sui::dynamic_object_field as ofiled;

    struct AuctionInfo<T1: key+store,phantom T2>has key,store{
        id: UID,
        item: Option<T1>,
        min_price: u64,
        start: u64,
        ends: u64,
        funds: Option<Coin<T2>>,
        highest_bidder: address,
    }

    struct Auction<phantom T> has key {
        id: UID,
        creator: address,
        item_id: ID,
    }
    struct AuctionEvent has copy,drop{
        auction_id: ID,
        item_id: ID,
        owner: address,
        min_price: u64,
        start: u64,
        ends: u64,
    }

    struct BidEvent has copy,drop{
        auction_id: ID,
        item_id: ID,
        bider: address,

        amount: u64,
    }

    struct AuctionEndEvent has copy,drop{
        auction_id: ID,
        highest_bidder: address,
    }

    const EEpochNotYetEnded :u64=0;
    const ENotOwner:u64=1;
    const ENoExceedsMinPrice: u64=2;
    const ENoExceedsHighestBid: u64=3;
    const EBidTimeNoStart: u64=4;
    const EBidTimeAlReadyEnd: u64=5;
    const EBidTimeNoEnd: u64=6;

    public(friend) fun auction_creator<T: key + store>(auction: &Auction<T>): address {
        auction.creator
    }

    public entry fun create_auction<T1: key + store,T2>(
        item: T1,
        min_price: u64,
        start: u64,
        ends: u64, ctx: &mut TxContext
    ) {
        let item_id=object::id(&item);
        let auction= Auction<T1> {
            id: object::new(ctx),
            creator:tx_context::sender(ctx),
            item_id
        };
        let auction_info=AuctionInfo<T1,T2>{
            id: object::new(ctx),
            item: option::some(item),
            min_price,
            start,
            ends,
            funds: option::none(),
            highest_bidder: tx_context::sender(ctx),
        };
        event::emit(AuctionEvent{
            auction_id: object::id(&auction),
            item_id ,
            owner: tx_context::sender(ctx),
            min_price,
            start,
            ends,
        });
        ofiled::add(&mut auction.id,item_id,auction_info);
        transfer::share_object(auction);
    }

    public  entry  fun bid<T1: key + store,T2>( auction: &mut Auction<T1>,
                                                funds: Coin<T2>,
                                                ctx: &mut TxContext){
        let item_id=auction.item_id;
        let auction_id=object::id(auction);
        let item_info=ofiled::borrow_mut<ID,AuctionInfo<T1,T2>>(&mut auction.id,item_id);
        assert!(tx_context::epoch(ctx)>=item_info.start,EBidTimeNoStart);
        assert!(tx_context::epoch(ctx)<=item_info.ends,EBidTimeAlReadyEnd);
        let bid_amount=coin::value(&funds);
        assert!(bid_amount>=item_info.min_price,ENoExceedsMinPrice);
        if (option::is_none(&item_info.funds)){
            option::fill(&mut item_info.funds,funds);
            event::emit(BidEvent{
                auction_id,
                item_id,
                bider: tx_context::sender(ctx),
                amount: bid_amount,
            });
            item_info.highest_bidder=tx_context::sender(ctx);
        }else{
            let current_highest_amount=coin::value(option::borrow(&item_info.funds));
            assert!(bid_amount>current_highest_amount,ENoExceedsHighestBid);
            let pre_bid=option::swap(&mut item_info.funds,funds);
            let amount=coin::value(&pre_bid);
            event::emit(BidEvent{
                auction_id,
                item_id,
                bider: tx_context::sender(ctx),
                amount,
            });
            transfer::transfer(pre_bid, item_info.highest_bidder);
            item_info.highest_bidder=tx_context::sender(ctx);
        }

    }


    public entry fun end_auction<T1: key + store,T2>(auction: &mut Auction<T1>,ctx: &mut TxContext){
        let item_id=auction.item_id;
        let item_info=ofiled::remove<ID,AuctionInfo<T1,T2>>(&mut auction.id,item_id);

        let AuctionInfo<T1,T2>{
            id,
            item,
            min_price:_,
            start:_,
            ends,
            funds,
            highest_bidder,
        }=item_info;
        assert!(tx_context::epoch(ctx)>ends,EBidTimeNoEnd);

        let auction_item=option::extract(&mut item);

        let fund=option::extract(&mut funds);

        transfer::transfer(auction_item,highest_bidder);

        transfer::transfer(fund,auction.creator);

        object::delete(id);
        option::destroy_none(item);
        option::destroy_none(funds);

    }
}