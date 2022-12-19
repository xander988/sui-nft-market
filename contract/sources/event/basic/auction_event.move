// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::auction_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::auction;

    struct ItemAuctionCretedEvent has copy, drop {
        auction_id: ID,
        item_id: ID,
        owner: address,
        min_price: u64,
        start: u64,
        end: u64,
    }

    struct ItemBidEvent has copy, drop {
        auction_id: ID,
        item_id: ID,
        bider: address,
        amount: u64,
    }

    struct ItemAuctionCompeletedEvent has copy, drop {
        auction_id: ID,
        highest_bidder: address,
        sale_amount: u64,
    }

    public(friend) fun create_auction_event(auction_id: ID,
                                            item_id: ID,
                                            owner: address,
                                            min_price: u64,
                                            start: u64,
                                            end: u64) {
        event::emit(ItemAuctionCretedEvent {
            auction_id,
            item_id,
            owner,
            min_price,
            start,
            end
        })
    }

    public(friend) fun item_bid_event(auction_id: ID,
                                      item_id: ID,
                                      bider: address,
                                      amount: u64) {
        event::emit(ItemBidEvent {
            auction_id,
            item_id,
            bider,
            amount
        })
    }

    public(friend) fun item_auction_compeleted_event(auction_id: ID,
                                                     highest_bidder: address,
                                                     sale_amount: u64) {
        event::emit(ItemAuctionCompeletedEvent {
            auction_id,
            highest_bidder,
            sale_amount
        })
    }
}
