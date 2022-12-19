module swift_nft::err_code {
    // ///market errcode

    const Prefix: u64=66666;
    // const EAmountIncorrect: u64 = 0;
    // const ENotOwner: u64 = 1;
    // const EAmountZero: u64 = 2;
    // const EOwnerAuth: u64 = 3;
    // const EObjectNotExist: u64 = 4;
    // const EAlreadyExistCollectionType: u64 = 5;
    //
    // ///fragment  errcode
    // const EItemMismatch: u64 = 0;
    // const EItemNumberNotEnough: u64 = 1;
    // const EItemExist: u64 = 2;
    // const EFragmentZero: u64 = 3;
    //
    //
    // ///bid
    // const EBidObjectMismatch: u64 = 0;
    // const ECoinType: u64 = 1;
    // const ETimeLocking: u64 = 2;
    // const ETwoObjectMismatch: u64 = 3;
    // const ENoAuth: u64 = 4;
    // const EObjectNoExist: u64 = 5;
    //
    // ///auction
    // const EEpochNotYetEnded: u64 = 0;
    // const ENotOwner: u64 = 1;
    // const ENoExceedsMinPrice: u64 = 2;
    // const ENoExceedsHighestBid: u64 = 3;
    // const EBidTimeNoStart: u64 = 4;
    // const EBidTimeAlReadyEnd: u64 = 5;
    // const EBidTimeNoEnd: u64 = 6;
    // const EBidPriceTooLow: u64 = 7;
    //
    // ///
    // ///
    // ///
    public fun coin_amount_in_below_price(): u64{
        return Prefix+01
    }

    public fun operator_not_auth(): u64{
        return Prefix+02
    }

    public  fun amount_is_zero(): u64{
        return Prefix+03
    }

    public fun object_not_exist():u64{
        return Prefix+04
    }




}
