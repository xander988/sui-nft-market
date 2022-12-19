// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::bid_event {
    use sui::object::ID;
    use sui::event;
    friend swift_nft::bid;

    struct ItemBidEvent has copy, drop {
        item_id: ID,
        bider: address,
        amount: u64,
    }

    struct BidCompleteEvent has copy, drop {
        item_id: ID,
        bid_id: ID,
        success: bool,
        operator: address,
        amount: u64,
    }

    struct BidCancelEvent has copy, drop {
        item_id: ID,
        bid_id: ID,
        operator: address,
    }

    struct BidUnlockEvent has copy, drop {
        bid_id: ID,
        success: bool,
        operator: address,
    }


    public(friend) fun item_bid_event(item_id: ID,
                                      bider: address,
                                      amount: u64) {
        event::emit(ItemBidEvent {
            item_id,
            bider,
            amount
        })
    }

    public(friend) fun bid_complete_event(item_id: ID,
                                          bid_id: ID,
                                          success: bool,
                                          operator: address,
                                          amount: u64,
    ) {
        event::emit(BidCompleteEvent {
            item_id,
            bid_id,
            success,
            operator,
            amount
        })
    }

    public(friend) fun bid_cancel_event(item_id: ID,
                                        bid_id: ID,
                                        operator: address) {
        event::emit(BidCancelEvent {
            item_id,
            bid_id,
            operator
        })
    }

    public(friend) fun bid_unlock_event(bid_id: ID,
                                        success: bool,
                                        operator: address) {
        event::emit(BidUnlockEvent {
            bid_id,
            success,
            operator
        })
    }
}
