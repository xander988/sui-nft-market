module swift_nft::whitelist {
    use sui::object::{UID,ID};
    use swift_nft::sale::Sale;
    use sui::tx_context::TxContext;
    use sui::object;
    use sui::transfer;
    use sui::tx_context;
    use std::bcs;
    use std::vector;
    use swift_nft::merkle_proof;
    use sui::vec_set::{Self,VecSet};
    use swift_nft::wl_event;

    struct Activity<phantom Item,phantom Market>has key,store{
        id:  UID,
        sale_id: ID,
        root: vector<u8>,
        claimed: VecSet<address>
    }

    struct WhiteListToken<phantom Item,phantom Market> has key,store{
        id: UID,
        sale_id: ID,
    }
    const ENotAuthGetWhiteList: u64=0;
    const ECreditAlreadyClaimed: u64=1;

    public fun create_activity<Item: key+store, Market:store>(sale: &Sale<Item,Market>,root: vector<u8>,ctx: &mut TxContext){
          let activity=Activity<Item,Market>{
              id: object::new(ctx),
              sale_id: object::id(sale),
              root,
              claimed: vec_set::empty<address>(),
          };
        wl_event::activity_create_event<Item,Market>(object::id(&activity),object::id(sale));
        transfer::share_object(activity);
    }


    public fun create_whitelist<Item: key+store, Market: store>(activity: &mut Activity<Item,Market>,proof: vector<vector<u8>>,ctx: &mut TxContext){
        assert!(vec_set::contains(&mut activity.claimed,&tx_context::sender(ctx)),ECreditAlreadyClaimed);

        let decode_data=bcs::to_bytes(ctx);
        let sender=vector_slice(&decode_data,0,20);
        let legal=merkle_proof::verify(proof,activity.root,sender);
        assert!(legal,ENotAuthGetWhiteList);
        let wl_credit=WhiteListToken<Item,Market>{
            id: object::new(ctx),
            sale_id:activity.sale_id
        };
        wl_event::whitelist_create_event<Item,Market>(object::id(&wl_credit),tx_context::sender(ctx));
        vec_set::insert(&mut activity.claimed,tx_context::sender(ctx));
        transfer::transfer(wl_credit,tx_context::sender(ctx));

    }

    public fun destory<Item: key+store, Market: store>(wl :WhiteListToken<Item,Market>,ctx: &mut TxContext){
        wl_event::whitelist_destory_event<Item,Market>(object::id(&wl),tx_context::sender(ctx));

        let WhiteListToken<Item,Market>{
            id,
            sale_id:_,
        }=wl;

        object::delete(id);
    }
    public fun get_wl_sale_id<Item: key+store, Market: store>(wl :&WhiteListToken<Item,Market>): ID{
        return  wl.sale_id
    }

    public fun vector_slice<T: copy>(v: &vector<T>,start: u64, end: u64): vector<T>{
        let new=vector::empty<T>();
        let index=start;
        while (index < end){
            vector::push_back(&mut new,*vector::borrow(v,index));
            index=index+1
        };
        return new
    }

}
