import "./jettonToken";

const minTonsForStorage: Int = ton("0.05");
const gasConsumption: Int = ton("0.05");

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    admin: Address;
}

struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

// ---------------------------------------------------------------------------------------------------- //=
contract NftCollection {
    next_item_index: Int as uint32 = 0;
    admin: Address;
    royalty_params: RoyaltyParams;                      
    collection_content: Cell;   

    fractionalized_nft: map<Int, Int>;  // Index_ID => NFT_ID
    fractional_index: Int as uint32 = 0; // The index counter of fractionalized NFT
    redeem_index:  Int as uint32 = 0; // The index counter of redeemed NFT index 

    init(admin: Address, collection_content: Cell, royalty_params: RoyaltyParams){
        self.admin = admin;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
    }

    receive("Mint"){
        let ctx: Context = context(); // get sender Info
        let restValue: Int = self.restTransactionValue(ctx.value)
        self.mint(ctx.sender, restValue);
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msgValue, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.admin,
                    custom_payload: emptyCell(),
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    // ===== Fractionalized ===== //
    receive(msg: Fractionalize) {
        let ctx: Context = context();
        require(ctx.sender == self.get_nft_address_by_index(msg.item_index), "not from NFT Item");

        // Store the information of fractionalized NFT
        self.fractionalized_nft.set(msg.item_index, self.fractional_index);  // [NFT_ID => Index_ID]
        self.fractional_index = self.fractional_index + 1;                  // Index_ID++

        // Create a new NFT Item
        let token_init: StateInit = initOf Jetton_Root(self.admin, myAddress());
        self.forward(
            contractAddress(token_init),
            TokenMinting {  // 0xac33de2f
                collection_address: myAddress(), 
                original_applicant: msg.original_applicant
            }.toCell(),
            false,
            token_init
        );
    }

    // Someone's Jetton Wallet will have Jetton Token and want to redeem it.
    receive(msg: Defractionalize) {
        let ctx: Context = context();
        require(ctx.sender == self.getTokenAddress(), "not from Jetton Token");

        // Clean up the record
        let redeem_nft_id: Int = self.fractionalized_nft.get(self.redeem_index)!!;
        self.fractionalized_nft.set(self.redeem_index, null); // TODO: Gas consumption will increase or not? 
        self.redeem_index = self.redeem_index + 1;

        self.forward(
            self.get_nft_address_by_index(redeem_nft_id)!!,
            RedeemNftItem { new_owner: msg.sender }.toCell(),
            false,
            null
        );
    }

    receive(){}
    receive(str: String) {}
    receive(slice: Slice) {}
    // receive(bounced: bounced){}
    
    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  self.royalty_params.numerator,
                denominator: self.royalty_params.denominator,
                destination: self.admin
            }.toCell()
        });        
    }
    
    fun restTransactionValue(msgValue: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return msgValue - (storageFee + gasConsumption);
    }

    get fun getTokenAddress(): Address {
        let winit: StateInit = initOf Jetton_Root(self.admin, myAddress());
        return contractAddress(winit);
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData{     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            admin: self.admin
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.admin, self.collection_content);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }
}

// ---------------------------------------------------------------------------------------------------- //=
contract NftItem {
    collection_address: Address;
    item_index: Int; 
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;

    locked: Bool;

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell){
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = collection_address;
        self.individual_content = individual_content;
        self.is_initialized = false;
        self.locked = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context();
    
        let msgValue: Int = ctx.value; // Check the gasCost for storage
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);

        require(ctx.sender == self.owner, "not owner");
        require(self.locked == false, "locked");
        if (self.is_initialized == false) {  // Initial Transfer, aka Minting.
            self.is_initialized = true;
            self.owner = msg.new_owner;
            send(SendParameters{
                to: msg.response_destination,
                value: 0,
                mode:  SendIgnoreErrors + SendRemainingValue,
                body: Excesses { query_id: msg.query_id }.toCell()  // 0xd53276db
                // body: x{D53276DB0000000000000000}
            });
        } else {
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode: SendIgnoreErrors, 
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner:  self.owner,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }
            
            msgValue = msgValue - ctx.readForwardFee(); 
            if (msg.response_destination != null) { 
                send(SendParameters{ 
                    to: msg.response_destination,
                    mode: SendIgnoreErrors,
                    value: msgValue,
                    body: Excesses { query_id: msg.query_id }.toCell() // 0xd53276db
                });
                self.owner = msg.new_owner; // change current owner to the new_owner
            } 
        }
    }
    
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.owner
            }.toCell()
        });
    }

    receive("f") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");
        self.locked = true;
        send(SendParameters{
            to: self.collection_address,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue, 
            bounce: false,
            body: Fractionalize {
                item_index: self.item_index,
                original_applicant: ctx.sender
            }.toCell()
        });
    }

    receive(msg: RedeemNftItem) {
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "not from collection");
        require(self.locked == true, "not locked");
        self.locked = false;
        self.owner = msg.new_owner;
        send(SendParameters{
            to: msg.new_owner,
            value: 0,
            mode: SendIgnoreErrors + SendRemainingValue,
            bounce: false,
            body: "Congrats".asComment()
        });
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = self.individual_content.asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: b.toCell()
        };
    }
}

struct GetNftData { 
    is_initialized: Bool;
    index: Int;
    collection_address: Address; 
    owner_address: Address;
    individual_content: Cell;
}