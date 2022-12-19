// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::fragment {
    use sui::object::{UID, ID};
    use std::option;
    use sui::balance;
    use sui::sui::SUI;
    use sui::object;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::string;
    use sui::url::{Self, Url};
    use sui::tx_context;
    use sui::coin;
    use sui::event;
    use sui::balance::Balance;

    struct NFTFragment<T: key+store> has key, store {
        id: UID,
        split_num: u64,
        burn_num: u64,
        percent: u64,
        item_id: ID,
        item: option::Option<T>,
        locked_balance: option::Option<Balance<SUI>>
    }

    struct SingleFragment<phantom T> has key, store {
        id: UID,
        item_id: ID,
        name: string::String,
        description: string::String,
        url: Url,
        number: u64,
    }

    struct NFTFragmentCreateEvent has copy, drop {
        item_id: ID,
        fragment_collection: ID,
        split_num: u64,
        percent: u64,
        owner: address
    }

    struct WithdrawFragmentNFTEvent has copy, drop {
        item_id: ID,
        number: u64,
        percent: u64,
        spend_sui: u64,
    }

    struct SwapSuiEvent has copy, drop {
        item_id: ID,
        percent: u64,
        swap_sui: u64,
    }

    const EItemMismatch: u64 = 0;
    const EItemNumberNotEnough: u64 = 1;
    const EItemExist: u64 = 2;
    const EFragmentZero: u64 = 3;

    fun create_fragment<T: store+key>(item: T, split_num: u64, percent: u64,
                                      name: vector<u8>,
                                      description: vector<u8>,
                                      url: vector<u8>,
                                      ctx: &mut TxContext) {
        let item_id = object::id(&item);
        let nft = SingleFragment<T> {
            id: object::new(ctx),
            item_id,
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            number: split_num,
        };
        let nft_fragment = NFTFragment<T> {
            id: object::new(ctx),
            split_num,
            burn_num: 0,
            percent,
            item_id: object::id(&item),
            item: option::some(item),
            locked_balance: option::some(balance::zero<SUI>()),
        };
        event::emit(NFTFragmentCreateEvent {
            item_id,
            fragment_collection: object::id(&nft),
            split_num,
            percent,
            owner: tx_context::sender(ctx),
        });
        transfer::share_object(nft_fragment);
        transfer::transfer(nft, tx_context::sender(ctx))
    }


    fun withdraw_nft<T: key+store>(
        single: SingleFragment<T>,
        fragment: &mut NFTFragment<T>,
        payment: balance::Balance<SUI>,
        receiver: address
    ) {
        let SingleFragment<T> { id: single_id, item_id, name: _, description: _, url: _, number } = single;
        let item = option::extract(&mut fragment.item);
        let borrow_item_id = object::id(&item);
        assert!(item_id == borrow_item_id, EItemMismatch);
        assert!(number * 10000 / fragment.split_num >= fragment.percent, EItemNumberNotEnough);
        let spend_sui = balance::value(&payment);
        let bal = option::borrow_mut(&mut fragment.locked_balance);
        balance::join(bal, payment);
        //fragment.locked_balance=option::some(bal);
        fragment.burn_num = number;
        event::emit(WithdrawFragmentNFTEvent {
            item_id,
            number,
            percent: number * 10000 / fragment.split_num,
            spend_sui
        });
        transfer::transfer(item, receiver);
        object::delete(single_id);
    }

    fun swap_sui<T: key+store>(
        single: SingleFragment<T>,
        fragment: &mut NFTFragment<T>,
        price: u64,
        ctx: &mut TxContext
    ) {
        let SingleFragment<T> { id, item_id, name: _, description: _, url: _, number } = single;
        assert!(option::is_none(&fragment.item), EItemExist);
        let borrow_item_id = fragment.item_id;
        assert!(item_id == borrow_item_id, EItemMismatch);
        let percent = 10000 * number / fragment.split_num;
        let calc_num = percent * price;
        let bal = option::borrow_mut(&mut fragment.locked_balance);
        let balance_num = balance::value(bal);
        // let  bal=option::borrow_mut(&mut fragment.locked_balance);
        //      balance::join(bal,payment);
        assert!(calc_num > 0 && balance_num >= calc_num, EFragmentZero);
        let receiver_balance = coin::from_balance(balance::split(bal, calc_num), ctx);
        fragment.burn_num = fragment.burn_num + number;
        event::emit(SwapSuiEvent {
            item_id,
            percent,
            swap_sui: calc_num,
        });
        transfer::transfer(receiver_balance, tx_context::sender(ctx));
        object::delete(id);
    }

    public entry fun join<T: key+store>(self: &mut SingleFragment<T>, c: SingleFragment<T>) {
        let SingleFragment<T> { id, item_id: _, name: _, description: _, url: _, number } = c;
        object::delete(id);
        self.number = self.number + number;
    }

    public fun split<T: key+store>(
        self: &mut SingleFragment<T>, split_amount: u64, ctx: &mut TxContext
    ): SingleFragment<T> {
        self.number = self.number - split_amount;
        SingleFragment<T> {
            id: object::new(ctx),
            item_id: self.item_id,
            name: self.name,
            description: self.description,
            url: self.url,
            number: split_amount
        }
    }
}
