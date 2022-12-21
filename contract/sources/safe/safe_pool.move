module swift_nft::safe_pool {

    use sui::object::{Self,UID,ID};
    use sui::object_table::{Self,ObjectTable};
    use sui::table::{Self,Table};
    use sui::vec_map::{Self,VecMap};
    use sui::vec_set::{Self,VecSet};
    use std::string::String;
    use sui::tx_context::TxContext;

    ///long-term lease  mutable(exclusive item)   high fee(is setting by item's ownerself or system) unique
    ///long-term lease  immutable(multi use )     low fee(is setting by item's ownerself or system)  multiple
    ///listing and flashloan are managed through two systems
    ///the owner himself mutable/immutable reference in gaming(The Item is muti listed in marketplace)
    /// flashloan mutable   fee(is setting by item's ownerself or system)
    /// flashloan immutable fee(is setting by item's ownerself or system)
    ///item is listed in market cannot long-term lease
    struct SafePool<phantom Item:key+store> has key{
        id: UID,
        ///
        nfts: ObjectTable<ID, Item>,
        nicknames: Table<String, ID>,
        owner_cap: VecMap<ID,ID>,
        borrow_cap:  VecMap<ID,ID>,
        listed: VecMap<ID,u64>,
        immutable_borrowed: VecMap<ID,u64>,
        mutable_borrowed: VecSet<ID>,
        flash_loan: VecSet<ID>,
    }


    struct OwnerCap<phantom  Item> has key {
        id: UID,
        safe_id: ID,
        item_id: ID,
    }

    /// Gives the holder permission to transfer the nft with id `nft_id` out of
    /// the safe with id `safe_id`. Can only be used once.
    struct TransferCap<phantom  Item> has key {
        id: UID,

        owner_id: ID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        /// The ID of the NFT that this capability can transfer
        item_id: ID,
    }

    /// Gives the holder permission to borrow the nft with id `nft_id` out of
    /// the safe with id `safe_id`. Can be used an arbitrary number of times.
    struct BorrowCap<phantom  Item> has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        /// The ID of the NFT that this capability can transfer
        item_id: ID,

    }


    struct FlashLoanReceipt<phantom Item>{
        safe_id: ID,
        item_id: ID,
    }



    /// "Hot potato" wrapping the borrowed NFT. Must be returned to `safe_id`
    /// before the end of the current transaction
    struct Borrowed<phantom Item> has key {
        id: UID,

        borrow_cap_id: ID,

        safe_id: ID,
        item_id: ID,
        active: bool
    }


    /// Create and share a fresh Safe that can hold T's.
    /// Return an `OwnerCap` for the Safe
    public fun create<Item: key+store>(ctx: &mut TxContext):SafePool<Item>{
        let self=SafePool<Item>{

            id: object::new(ctx),
            nfts: object_table::new<ID,Item>(ctx),
            nicknames: table::new<String,ID>(ctx),
            owner_cap: vec_map::empty<ID,ID>(),

            borrow_cap: vec_map::empty<ID,ID>(),

            listed: vec_map::empty<ID,u64>(),

            immutable_borrowed: vec_map::empty<ID,u64>(),
            mutable_borrowed: vec_set::empty<ID>(),

            // flash_immutable_borrowed: VecMap<ID,u64>,
            flash_loan: vec_set::empty<ID>(),

        };

        self

    }

    const ENftIDMismatch: u64=1;
    const ESafeIDMismatch: u64=2;
    const EOwnerCapNotlegal: u64=3;
    const EItemIDBorrowCapAlreadyExist:u64=4;
    const ETwoOwnerIDMismatch: u64=5;
    const EItemLongTermLease: u64=6;
    const EItemNotListing: u64=7;
    const EItemAlreadyLongTermOrMutableLease: u64=8;



    public fun add_item<Item: key+store>(self: &mut SafePool<Item>,item: Item,ctx: &mut TxContext): (OwnerCap<Item>,BorrowCap<Item>){
        let nfts=&mut self.nfts;
        let item_id=object::id(&item);
        object_table::add(nfts,item_id,item);
        //get
        let owner_cap=OwnerCap<Item>{
            id: object::new(ctx),
            safe_id: object::id(self),
            item_id,
        };
        let borrow_cap=BorrowCap<Item>{
            id: object::new(ctx),
            safe_id: object::id(self),
            item_id,
        };
        (owner_cap,borrow_cap)
    }


    fun remove_item<Item: key+store>(self: &mut SafePool<Item>,item_id: ID): Item{
        //remove owner_cap
        vec_map::remove(&mut self.owner_cap,&item_id);
        //remove borrow_cap
        vec_map::remove(&mut self.borrow_cap,&item_id);

        //remove mutable borrowed
        if (vec_set::contains(&self.mutable_borrowed,&item_id)){
            vec_set::remove(&mut self.mutable_borrowed,&item_id);
        };
        //remove immutable borrowed
        if (vec_map::contains(& self.immutable_borrowed,&item_id)){
            vec_map::remove(&mut self.immutable_borrowed,&item_id);
        };

        //remove transfer list
        if (vec_map::contains(&self.listed,&item_id)){
            vec_map::remove(&mut self.listed,&item_id);
        };
        let item=object_table::remove<ID,Item>(&mut self.nfts,item_id);

        item
    }



    /// Produce a `TransferCap` for the NFT with `id` in `safe`.
    /// This `TransferCap` can be (e.g.) used to list the NFT on a marketplace.
    ///
    public fun sell_nft<Item:  key+store>(self: &mut SafePool<Item>,owner_cap: &OwnerCap<Item>,  item_id: ID,ctx: &mut TxContext): TransferCap<Item> {
        let safe_id=object::id(self);
        let owner_id=object::id(owner_cap);
        assert!(safe_id==owner_cap.safe_id,4);
        assert!(item_id==owner_cap.item_id,5);
        assert!(vec_map::get(&self.owner_cap,&item_id)==&owner_id,6);

        let transferCap=TransferCap<Item>{
            id: object::new(ctx),
            owner_id,
            safe_id,
            item_id,
        };
        if (!vec_map::contains(&mut self.listed,&item_id)){
            vec_map::insert(&mut self.listed, item_id,1)
        }else{
            let listing_num=vec_map::get_mut(&mut self.listed,&item_id);
            *listing_num=*listing_num+1
            //vec_map::insert(&mut self.listed,item_id,listing_num+1)
        };
        return transferCap
    }

    /// Consume `cap`, remove the NFT with `id` from `safe`, and return it to the caller.
    /// Requiring `royalty` ensures that the caller has paid the required royalty for this collection
    /// before completing  the purchase.
    /// This invalidates all other `TransferCap`'s by increasing safe.transfer_cap_version
    ///todo params royalty: RoyaltyReceipt<Item>
    ///
    ///
    public fun buy_nft<Item: key+store,CoinType>(safe: &mut SafePool<Item>,transfer_cap: TransferCap<Item>, item_id: ID): Item {

        let safe_id=object::id(safe);

        assert!(safe_id==transfer_cap.safe_id,ESafeIDMismatch);
        assert!(item_id==transfer_cap.item_id,ENftIDMismatch);
        assert!(vec_map::get(&safe.owner_cap,&item_id)==&transfer_cap.owner_id,5);

        //remove owner_cap
        vec_map::remove(&mut safe.owner_cap,&item_id);
        //remove borrow_cap
        vec_map::remove(&mut safe.borrow_cap,&item_id);
        //remove borrowed list
        vec_set::remove(&mut safe.mutable_borrowed,&item_id);
        vec_map::remove(&mut safe.immutable_borrowed,&item_id);

        //remove transfer list
        vec_map::remove(&mut safe.listed,&item_id);

        let TransferCap<Item>{
            id,
            owner_id:_,
            safe_id: _,

            item_id: _,
        }=transfer_cap;

       object::delete(id);

       remove_item(safe,item_id)
    }

    public fun unborrow_nft<T: key+store>(self: &mut SafePool<T>,borrow_cap: Borrowed<T>){

        let Borrowed<T>{
            id,
            borrow_cap_id:_,
            safe_id: _,
            item_id,

            active,
        }=borrow_cap;
        if (active){
            vec_set::remove(&mut self.mutable_borrowed,&item_id)
        };
        let immutable_num=vec_map::get_mut(&mut self.immutable_borrowed,&item_id);
        if(*immutable_num>0){
            *immutable_num=*immutable_num-1;
        };
       // let num=*vec_map::get(&mut self.immutable_borrowed,&item_id);
        if (*immutable_num==0){
            vec_map::remove(&mut self.immutable_borrowed,&item_id);
        };


        object::delete(id)
    }

    public fun borrow_nft<Item :key+store>(self: &mut SafePool<Item>,borrow_cap: &BorrowCap<Item>,item_id: ID,active: bool,ctx: &mut TxContext): Borrowed<Item> {
        //let(immutable_num,mutable_num)=(0,0);
        let safe_id=object::id(self);
        assert!(safe_id==borrow_cap.safe_id,5);
        assert!(item_id==borrow_cap.item_id,6);
        assert!(!vec_set::contains(&self.mutable_borrowed,&item_id),5);
        let immutable_num=if (vec_map::contains(&self.immutable_borrowed,&item_id)){
            let num=*vec_map::get(& self.immutable_borrowed,&item_id);
            num
        }else{
            0
        };
        assert!(!(active && immutable_num>0),6);

        let borrow_cap_id=object::id(borrow_cap);

        assert!(borrow_cap_id==*vec_map::get(&mut self.borrow_cap,&item_id),1);

        if (active){
            vec_set::insert(&mut self.mutable_borrowed,item_id)
        };
        if (immutable_num>0){
            let immutable_num1=vec_map::get_mut(&mut self.immutable_borrowed,&item_id);
            *immutable_num1=*immutable_num1+1
        };

        let borrowed=Borrowed<Item>{
            id: object::new(ctx),
            borrow_cap_id,

            safe_id,

            item_id,

            active
        };
        return borrowed
    }






    public fun get_nft_mut<T: key+store>(safe: &mut SafePool<T>,borrowed: &mut Borrowed<T>): &mut T {
        assert!(borrowed.active==true,3);
        return object_table::borrow_mut(&mut safe.nfts,borrowed.item_id)
    }


    public fun get_nft<T: key+store>(safe: &mut SafePool<T>,borrowed: &mut Borrowed<T>): &T {
        return object_table::borrow(&mut safe.nfts,borrowed.item_id)
    }



    public fun flash_loan_item<Item: key+store>(
        self: &mut SafePool<Item>,  item_id: ID,
    ): (Item, FlashLoanReceipt<Item>) {

        assert!(!vec_set::contains(&self.flash_loan,&item_id),1);
        //check item_id no exist in  mutable borrow
        assert!(!vec_set::contains(&self.mutable_borrowed,&item_id),2);

        let items=&mut self.nfts;

        assert!(object_table::contains(items,item_id),3);


        vec_set::insert(&mut self.flash_loan,item_id);
        let item=object_table::remove(items,item_id);

        let flash_loan_receipt=FlashLoanReceipt<Item>{
            safe_id: object::id(self),
            item_id: object::id(&item),
        };

        (item,flash_loan_receipt)
    }

    public  fun replay_item<Item: key+store>(
        self: &mut SafePool<Item>,
        receipt: FlashLoanReceipt<Item>,
        item: Item,
       ){
        let FlashLoanReceipt<Item>{
            safe_id,
            item_id,
        }=receipt;

        assert!(safe_id==object::id(self),4);
        assert!(item_id==object::id(&item),5);

        vec_set::remove(&mut self.flash_loan,&object::id(&item));
        let nfts=&mut self.nfts;

        object_table::add(nfts,item_id,item)

    }


}




