// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::safe {
    use sui::object::{Self,UID,ID};
    use sui::object_table::{Self,ObjectTable};
    use sui::table::{Self,Table};
    use sui::vec_map::{Self,VecMap};
    use sui::vec_set::{Self,VecSet};
    use std::string::String;
    use sui::tx_context::TxContext;
    use sui::transfer;



    struct Safe<phantom Item> has key {
        id: UID,
        /// NFT's in this safe, indexed by their ID's
        nfts: ObjectTable<ID, Item>,
        /// For easier naming/retrieval of NFT's. range is a subset of the domain of `nfts`
        nicknames: Table<String, ID>,
        /// ID's of NFT's that are currently listed for sale. These can only be borrowed immutably
        listed: VecSet<ID>,
        /// ID's of NFT's that are currently borrowed. These cannot be listed for sale while borrowing is active
        borrowed: VecSet<ID>,
        ///flash  borrowd
        flash_borrowed: VecSet<ID>,
        ///storing ID ===>valid  version
        /// ID===>OwnerCap ID
        owner_cap: VecMap<ID,ID>,
        /// Valid version for TransferCap's
        transfer_cap:  VecMap<ID,u64>,
        /// Valid version for BorrowCap's
        borrow_cap:  VecMap<ID,ID>,
        ///
        force_borrow: VecSet<ID>
    }


    struct OwnerCap<phantom  Item> has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        nft_id: ID,
        /// Version of this cap.
        version: u64,
    }

    /// Gives the holder permission to transfer the nft with id `nft_id` out of
    /// the safe with id `safe_id`. Can only be used once.
    struct TransferCap<phantom  Item> has key, store {
        id: UID,
        owner_id: ID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        /// The ID of the NFT that this capability can transfer
        nft_id: ID,
        version: u64
    }

    /// Gives the holder permission to borrow the nft with id `nft_id` out of
    /// the safe with id `safe_id`. Can be used an arbitrary number of times.
    struct BorrowCap<phantom  Item> has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        /// The ID of the NFT that this capability can transfer
        nft_id: ID,

        version: u64
    }

    struct FlashBorrowCap<phantom Item> has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,

        version: u64
    }

    struct FlashBorrowed<Item> {
        nft: Item,
        /// The safe that this NFT came from
        safe_id: ID,
        /// If true, only an immutable reference to `nft` can be granted
        /// Always false if the NFT is currently listed
        is_mutable: bool,
    }

    /// "Hot potato" wrapping the borrowed NFT. Must be returned to `safe_id`
    /// before the end of the current transaction
    struct Borrowed<phantom Item> has key {
        id: UID,

        borrow_cap: ID,

        nft_id: ID,
        /// The safe that this NFT came from
        safe_id: ID,

        status: bool,
        /// If true, only an immutable reference to `nft` can be granted
        /// Always false if the NFT is currently listed

        is_mutable: bool,
    }


    /// Create and share a fresh Safe that can hold T's.
    /// Return an `OwnerCap` for the Safe
    public fun create<Item: key+store>(ctx: &mut TxContext){
        let safe=Safe<Item>{
            id: object::new(ctx),
            /// NFT's in this safe, indexed by their ID's
            nfts: object_table::new<ID,Item>(ctx),
            /// For easier naming/retrieval of NFT's. range is a subset of the domain of `nfts`
            nicknames: table::new<String,ID>(ctx),
            /// ID's of NFT's that are currently listed for sale. These can only be borrowed immutably
            listed: vec_set::empty<ID>(),
            /// ID's of NFT's that are currently borrowed. These cannot be listed for sale while borrowing is active
            borrowed: vec_set::empty<ID>(),

            flash_borrowed: vec_set::empty<ID>(),
            ///Valid version for OwneCap's
            owner_cap: vec_map::empty<ID,ID>(),

            transfer_cap: vec_map::empty<ID,u64>(),

            borrow_cap: vec_map::empty<ID,ID>(),
            //borrow_cap: vec_map::empty<ID,u64>(),
            force_borrow: vec_set::empty<ID>()
        };
        transfer::share_object(safe)
    }

    const ENftIDMismatch: u64=1;
    const ESafeIDMismatch: u64=2;
    const EOwnerCapNotlegal: u64=3;
    const EItemIDBorrowCapAlreadyExist:u64=4;
    const ETwoOwnerIDMismatch: u64=5;
   // const ETwoSafeMismatch: u64=0;


    public fun add_item<Item: key+store>(safe: &mut Safe<Item>,item: Item,ctx: &mut TxContext): (OwnerCap<Item>,BorrowCap<Item>){
        ///add item to object_tables
        let safe_nfts=&mut safe.nfts;
        let item_id=object::id(&item);
        object_table::add(safe_nfts,item_id,item);
        //get
        let owner_cap=OwnerCap<Item>{
            id: object::new(ctx),
            safe_id: object::id(safe),
            nft_id: item_id,
            /// Version of this cap.
            version: 0,
        };
        let borrow_cap=BorrowCap<Item>{
            id: object::new(ctx),
            /// The ID of the safe that this capability grants permissions to
            safe_id: object::id(safe),
            /// The ID of the NFT that this capability can transfer
            nft_id: item_id,
            version: 0
        };
        (owner_cap,borrow_cap)
    }

    /// Produce a `TransferCap` for the NFT with `id` in `safe`.
    /// This `TransferCap` can be (e.g.) used to list the NFT on a marketplace.
    public fun sell_nft<Item>(safe: &mut Safe<Item>,owner_cap: &mut OwnerCap<Item>,  item_id: ID,ctx: &mut TxContext): TransferCap<Item> {
        //assert!(ve)
        assert!(!vec_set::contains(&safe.force_borrow,&item_id),1);
        let owner_nft_id=owner_cap.nft_id;
        let owner_safe_id=owner_cap.safe_id;
        let safe_id=object::id(safe);
        let legal_owner_id=vec_map::get(&safe.owner_cap,&item_id);
       // let legal=vec_set::contains(&safe.owner_cap,&object::id(owner_cap));
        assert!(owner_nft_id==item_id,ENftIDMismatch);
        assert!(owner_safe_id==safe_id,ESafeIDMismatch);
        assert!(*legal_owner_id==object::id(owner_cap),EOwnerCapNotlegal);

        let transferCap=TransferCap<Item>{
            id: object::new(ctx),
            owner_id: object::id(owner_cap),
            /// The ID of the safe that this capability grants permissions to
            safe_id,
            /// The ID of the NFT that this capability can transfer
            nft_id: item_id,
            version: 0
        };
        if (!vec_set::contains(&mut safe.listed,&item_id)){
            vec_set::insert(&mut safe.listed, item_id)
        };
        return transferCap
    }
    //
    /// Consume `cap`, remove the NFT with `id` from `safe`, and return it to the caller.
    /// Requiring `royalty` ensures that the caller has paid the required royalty for this collection
    /// before completing  the purchase.
    /// This invalidates all other `TransferCap`'s by increasing safe.transfer_cap_version
    ///todo params royalty: RoyaltyReceipt<Item>
    public fun buy_nft<Item: key+store,CoinType>(safe: &mut Safe<Item>,cap: TransferCap<Item>, item_id: ID): Item {
        assert!(!vec_set::contains(&safe.force_borrow,&item_id),1);

        check_purcahse(safe,&cap,item_id);

        let item=object_table::remove<ID,Item>(&mut safe.nfts,item_id);

        ///marked all transferCap and OwnerCap is illegal(or destory)
       item
    }


    // public fun borrow_nft<T>(borrow_cap: &BorrowCap<T>, safe: &mut Safe<T>): Borrowed<T> {
    //     abort(0)
    // }

    fun check_purcahse<Item: key+store>(safe: &mut Safe<Item>,cap: &TransferCap<Item>,item_id: ID){
        assert!(object::id(safe)==cap.safe_id,ESafeIDMismatch);
        assert!(item_id==cap.nft_id,ENftIDMismatch);
        let (_,remove_owner_cap_id)=vec_map::remove(&mut safe.owner_cap,&item_id);
        assert!(remove_owner_cap_id==cap.owner_id,ETwoOwnerIDMismatch);
        if (vec_map::contains(&mut safe.borrow_cap,&item_id)){
            vec_map::remove(&mut safe.borrow_cap,&item_id);
        };
        //remove borrow list
        vec_set::remove(&mut safe.borrowed,&item_id);
        assert!(vec_set::contains(&mut safe.borrowed,&item_id),3);
        //remove transfer list
        vec_set::remove(&mut safe.listed,&item_id);
        assert!(vec_set::contains(&mut safe.listed,&item_id),3);
    }

    ///
    /// Allow the holder of `borrow_cap` to borrow NFT specified in `borrow_cap` from `safe` for the duration
    /// of the current transaction
    ///
    // public fun borrow_nft<T>(safe: &mut Safe<T>,borrow_cap: &BorrowCap<T>,item_id: ID,ctx: &mut TxContext): Borrowed<T> {
    //     //check  BorrowCap ability legal
    //     let borrow_cap_id=object::id(borrow_cap);
    //
    //     let legal=vec_map::contains(&mut safe.borrow_cap,&borrow_cap_id);
    //     assert!(legal,1);
    //
    //     let borrowed=Borrowed<T>{
    //         id: object::new(ctx),
    //         borrow_cap: borrow_cap_id,
    //
    //         nft_id: item_id,
    //         /// The safe that this NFT came from
    //         safe_id: object::id(safe),
    //         status:
    //         /// If true, only an immutable reference to `nft` can be granted
    //         /// Always false if the NFT is currently listed
    //         is_mutable: false,
    //     };
    //
    //     return borrowed
    // }
    public fun unborrow_nft<T>(safe: &mut Safe<T>,borrow_cap: Borrowed<T>){

        let Borrowed<T>{
            id,
            borrow_cap:_,
            nft_id,
            /// The safe that this NFT came from
            safe_id: _,
            status,
            /// If true, only an immutable reference to `nft` can be granted
            /// Always false if the NFT is currently listed
            is_mutable: _,
        }=borrow_cap;
        if (status){
            vec_set::remove(&mut safe.force_borrow,&nft_id)
        }
    }

    public fun borrow_nft<T>(safe: &mut Safe<T>,borrow_cap: &BorrowCap<T>,item_id: ID,status: bool,ctx: &mut TxContext): Borrowed<T> {
        //check  BorrowCap ability legal
        assert!(!vec_set::contains(&safe.force_borrow,&item_id),1);

        let borrow_cap_id=object::id(borrow_cap);

        let legal=vec_map::contains(&mut safe.borrow_cap,&borrow_cap_id);

        assert!(legal,1);

        if (status){
            vec_set::insert(&mut safe.force_borrow,item_id)
        };

        let borrowed=Borrowed<T>{
            id: object::new(ctx),
            borrow_cap: borrow_cap_id,
            nft_id: item_id,
            /// The safe that this NFT came from
            safe_id: object::id(safe),
            status,
            /// If true, only an immutable reference to `nft` can be granted
            /// Always false if the NFT is currently listed
            is_mutable: false,
        };
        return borrowed
    }


    /// Get access
    public fun get_nft_mut<T: key+store>(safe: &mut Safe<T>,borrowed: &mut Borrowed<T>): &mut T {
        assert!(borrowed.is_mutable==true,3);

        return object_table::borrow_mut(&mut safe.nfts,borrowed.nft_id)
    }


    public fun get_nft<T: key+store>(safe: &mut Safe<T>,borrowed: &mut Borrowed<T>): &T {
        return object_table::borrow(&mut safe.nfts,borrowed.nft_id)
    }


}