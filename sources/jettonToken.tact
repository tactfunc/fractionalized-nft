import "./message";

contract Jetton_Root {
    total_supply: Int as coins;
    mintable: Bool;
    admin: Address;
    collection_address: Address;
    content: Cell?;
    jettoken_token_uint: Int as coins  = 1000 * 1000000000; // TODO: This equal to 100 TOKENS (Since we have 9 digits after the decimal point)

    init(admin: Address, collection_address: Address) {
        self.total_supply = 0;
        self.admin = admin;
        self.mintable = true;
        self.collection_address = collection_address;
    }

    // Upload Jetton Token Information
    receive(msg: UploadContent) {
        let ctx: Context = context();
        // require(ctx.sender == self.admin, "Only admin can upload content"); // NOTICE: Need to decomment this line
        self.content = msg.content;
        self.forward(self.admin, "Success".asComment(), false, null);
    }

    receive(msg: TokenMinting) { // 0xac33de2f
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "Only admin can mint tokens");
        self.mint_jetton(msg.original_applicant, self.jettoken_token_uint, self.admin);
    }

    fun mint_jetton(to: Address, amount: Int, responseAddress: Address) {
        // Update total supply
        self.total_supply = self.total_supply + amount;

        // Create message
        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: to,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    receive(msg: TokenBurnNotification) {
        let ctx: Context = context();
        require(ctx.sender == self.get_wallet_address(msg.owner), "Only wallet can burn tokens");
        require(msg.amount == self.jettoken_token_uint, "Invalid amount");
        require(self.total_supply - msg.amount >= 0, "Invalid total supply after burn");
        
        send(SendParameters{
            to: self.collection_address,
            value: self.msgValue(ctx.value),
            mode: SendIgnoreErrors,
            bounce: false,
            body: Defractionalize{ sender: msg.owner }.toCell()
        });

        self.burn(msg.amount, msg.queryId, msg.owner);
    }

    get fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        return msgValue;
    }

    fun burn(burnAmount: Int, queryId: Int, previous_ownerAddress: Address) {
        // Update total supply
        self.total_supply = self.total_supply - burnAmount;

        // Create message, return to the JettonWallet Address
        send(SendParameters{
            to: self.get_wallet_address(previous_ownerAddress),
            mode: SendPayGasSeparately,
            value: ton("0.0000001"),
            bounce: false,
            body: TokenExcesses{
                queryId: queryId
            }.toCell()
        });
    } 

    get fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }

    get fun get_jetton_data(): MasterData {
        return MasterData { 
            total_supply: self.total_supply, 
            mintable: self.mintable, 
            admin_address: self.admin, 
            jetton_content: self.content, 
            jetton_wallet_code: self.getJettonWalletInit(self.admin).code
        };
    }
}

struct MasterData {
    total_supply: Int;
    mintable: Bool;
    admin_address: Address;
    jetton_content: Cell?;
    jetton_wallet_code: Cell;
}


// ======================================== Jetton Wallet ========================================
contract JettonDefaultWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;
    jettoken_token_uint: Int as coins  = 1000 * 1000000000; // TODO: This equal to 100 TOKENS (Since we have 9 digits after the decimal point)

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }
    
    receive(){}

    receive(msg: TokenTransfer) {

        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee(); 
        // let fwdFee: Int = ctx.newReadForwardFee();
        let fwdCount: Int = 1;
        if (msg.forward_ton_amount > 0) {
            fwdCount = 2;
        }
        require(ctx.value > fwdCount * fwdFee + 2 * gasConsumption + minTonsForStorage, "Invalid value");

        // Send tokens
        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);
        let newOwner_walletAddress: Address = contractAddress(init);
        send(SendParameters{
            to: newOwner_walletAddress, 
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors, 
            bounce: true,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }

    receive(msg: TokenTransferInternal) { // 0x178d4519
        // Check sender
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance");

        // Forward ton
        if (msg.forward_ton_amount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        let msgValue: Int = self.msgValue(ctx.value);  // Get value for gas
        // let fwdFee: Int = ctx.newReadForwardFee();
        let fwdFee: Int = ctx.readForwardFee(); 
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;

        // Cashback
        if (msg.response_destination != null && msgValue > 0) {
            send(SendParameters{
                to: msg.response_destination,
                value: msgValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    receive("Redeem") {
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        require(ctx.value >= ton("0.3"), "not enough ton");

        // Update balance
        self.balance = self.balance - self.jettoken_token_uint;
        require(self.balance >= 0, "Invalid balance");

        // Gas checks
        // let fwdFee: Int = ctx.newReadForwardFee();
        let fwdFee: Int = ctx.readForwardFee(); 
        require(ctx.value > fwdFee + 2 * gasConsumption + minTonsForStorage, "Invalid value");

        // Burn tokens
        // require(myBalance > ton("0.1"), "Not enough ton in the Jetton Wallet Contract");
        send(SendParameters{
            to: self.master,
            value: ton("0.25"), // At least 0.1 ton in the Jetton Wallet Contract
            mode: SendIgnoreErrors + SendPayGasSeparately,
            bounce: true,
            body: TokenBurnNotification{
                queryId: 0,
                amount: self.jettoken_token_uint,
                owner: self.owner,
                responseAddress: myAddress()
            }.toCell()
        });
    }

    bounced(msg: Slice) {
        msg.skipBits(32); // 0xFFFFFFFF
        let op: Int = msg.loadUint(32);
        let queryId: Int = msg.loadUint(64);
        let jettonAmount: Int = msg.loadCoins();
        require(op == 0x178d4519 || op == 0x7bdd97de, "Invalid bounced message");

        // Update balance
        self.balance = self.balance + jettonAmount;
    }
    
    get fun msgValue(value: Int): Int {
        let msgValue: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        return msgValue;
    }

    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            code: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }
}

struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}