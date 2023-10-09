# TACT Compilation Report
Contract: Jetton_Root
BOC Size: 1853 bytes

# Types
Total Types: 28

## StateInit
TLB: `_ code:^cell data:^cell = StateInit`
Signature: `StateInit{code:^cell,data:^cell}`

## Context
TLB: `_ bounced:bool sender:address value:int257 raw:^slice = Context`
Signature: `Context{bounced:bool,sender:address,value:int257,raw:^slice}`

## SendParameters
TLB: `_ bounce:bool to:address value:int257 mode:int257 body:Maybe ^cell code:Maybe ^cell data:Maybe ^cell = SendParameters`
Signature: `SendParameters{bounce:bool,to:address,value:int257,mode:int257,body:Maybe ^cell,code:Maybe ^cell,data:Maybe ^cell}`

## MasterData
TLB: `_ total_supply:int257 mintable:bool admin_address:address jetton_content:Maybe ^cell jetton_wallet_code:^cell = MasterData`
Signature: `MasterData{total_supply:int257,mintable:bool,admin_address:address,jetton_content:Maybe ^cell,jetton_wallet_code:^cell}`

## TokenTransfer
TLB: `token_transfer#0f8a7ea5 queryId:uint64 amount:coins destination:address response_destination:address customPayload:Maybe ^cell forward_ton_amount:coins forward_payload:remainder<slice> = TokenTransfer`
Signature: `TokenTransfer{queryId:uint64,amount:coins,destination:address,response_destination:address,customPayload:Maybe ^cell,forward_ton_amount:coins,forward_payload:remainder<slice>}`

## TokenTransferInternal
TLB: `token_transfer_internal#178d4519 queryId:uint64 amount:coins from:address response_destination:address forward_ton_amount:coins forward_payload:remainder<slice> = TokenTransferInternal`
Signature: `TokenTransferInternal{queryId:uint64,amount:coins,from:address,response_destination:address,forward_ton_amount:coins,forward_payload:remainder<slice>}`

## TokenNotification
TLB: `token_notification#7362d09c queryId:uint64 amount:coins from:address forward_payload:remainder<slice> = TokenNotification`
Signature: `TokenNotification{queryId:uint64,amount:coins,from:address,forward_payload:remainder<slice>}`

## TokenBurn
TLB: `token_burn#595f07bc queryId:uint64 amount:coins owner:address response_destination:address = TokenBurn`
Signature: `TokenBurn{queryId:uint64,amount:coins,owner:address,response_destination:address}`

## TokenExcesses
TLB: `token_excesses#d53276db queryId:uint64 = TokenExcesses`
Signature: `TokenExcesses{queryId:uint64}`

## TokenUpdateContent
TLB: `token_update_content#0c087a9e content:Maybe ^cell = TokenUpdateContent`
Signature: `TokenUpdateContent{content:Maybe ^cell}`

## WalletData
TLB: `_ balance:int257 owner:address master:address code:^cell = WalletData`
Signature: `WalletData{balance:int257,owner:address,master:address,code:^cell}`

## UploadContent
TLB: `upload_content#58dee2a2 content:^cell = UploadContent`
Signature: `UploadContent{content:^cell}`

## TokenMinting
TLB: `token_minting#ac33de2f collection_address:address original_applicant:address = TokenMinting`
Signature: `TokenMinting{collection_address:address,original_applicant:address}`

## SafeTokenBurn
TLB: `safe_token_burn#e3df0a31 queryId:uint64 amount:coins owner:address responseAddress:Maybe address = SafeTokenBurn`
Signature: `SafeTokenBurn{queryId:uint64,amount:coins,owner:address,responseAddress:Maybe address}`

## TokenBurnNotification
TLB: `token_burn_notification#7bdd97de queryId:uint64 amount:coins owner:address responseAddress:Maybe address = TokenBurnNotification`
Signature: `TokenBurnNotification{queryId:uint64,amount:coins,owner:address,responseAddress:Maybe address}`

## CollectionData
TLB: `_ next_item_index:int257 collection_content:^cell admin:address = CollectionData`
Signature: `CollectionData{next_item_index:int257,collection_content:^cell,admin:address}`

## RoyaltyParams
TLB: `_ numerator:int257 denominator:int257 destination:address = RoyaltyParams`
Signature: `RoyaltyParams{numerator:int257,denominator:int257,destination:address}`

## Fractionalize
TLB: `fractionalize#f26348d9 item_index:uint32 original_applicant:address = Fractionalize`
Signature: `Fractionalize{item_index:uint32,original_applicant:address}`

## Defractionalize
TLB: `defractionalize#c004c6f1 sender:address = Defractionalize`
Signature: `Defractionalize{sender:address}`

## RedeemNftItem
TLB: `redeem_nft_item#ac4112b8 new_owner:address = RedeemNftItem`
Signature: `RedeemNftItem{new_owner:address}`

## Transfer
TLB: `transfer#5fcc3d14 query_id:uint64 new_owner:address response_destination:address custom_payload:Maybe ^cell forward_amount:coins forward_payload:remainder<slice> = Transfer`
Signature: `Transfer{query_id:uint64,new_owner:address,response_destination:address,custom_payload:Maybe ^cell,forward_amount:coins,forward_payload:remainder<slice>}`

## OwnershipAssigned
TLB: `ownership_assigned#05138d91 query_id:uint64 prev_owner:address forward_payload:remainder<slice> = OwnershipAssigned`
Signature: `OwnershipAssigned{query_id:uint64,prev_owner:address,forward_payload:remainder<slice>}`

## Excesses
TLB: `excesses#d53276db query_id:uint64 = Excesses`
Signature: `Excesses{query_id:uint64}`

## GetStaticData
TLB: `get_static_data#2fcb26a2 query_id:uint64 = GetStaticData`
Signature: `GetStaticData{query_id:uint64}`

## ReportStaticData
TLB: `report_static_data#8b771735 query_id:uint64 index_id:int257 collection:address = ReportStaticData`
Signature: `ReportStaticData{query_id:uint64,index_id:int257,collection:address}`

## GetNftData
TLB: `_ is_initialized:bool index:int257 collection_address:address owner_address:address individual_content:^cell = GetNftData`
Signature: `GetNftData{is_initialized:bool,index:int257,collection_address:address,owner_address:address,individual_content:^cell}`

## GetRoyaltyParams
TLB: `get_royalty_params#693d3950 query_id:uint64 = GetRoyaltyParams`
Signature: `GetRoyaltyParams{query_id:uint64}`

## ReportRoyaltyParams
TLB: `report_royalty_params#a8cb00ad query_id:uint64 numerator:uint16 denominator:uint16 destination:address = ReportRoyaltyParams`
Signature: `ReportRoyaltyParams{query_id:uint64,numerator:uint16,denominator:uint16,destination:address}`

# Get Methods
Total Get Methods: 4

## msgValue
Argument: value

## getJettonWalletInit
Argument: address

## get_wallet_address
Argument: owner

## get_jetton_data

# Error Codes
2: Stack undeflow
3: Stack overflow
4: Integer overflow
5: Integer out of expected range
6: Invalid opcode
7: Type check error
8: Cell overflow
9: Cell underflow
10: Dictionary error
13: Out of gas error
32: Method ID not found
34: Action is invalid or not supported
37: Not enough TON
38: Not enough extra-currencies
128: Null reference exception
129: Invalid serialization prefix
130: Invalid incoming message
131: Constraints error
132: Access denied
133: Contract stopped
134: Invalid argument
135: Code of a contract was not found
136: Invalid address
137: Masterchain support is not enabled for this contract
1045: not locked
4429: Invalid sender
13650: Invalid bounced message
16059: Invalid value
17062: Invalid amount
19671: locked
22185: not from NFT Item
26686: Only admin can mint tokens
38283: not from Jetton Token
49280: not owner
49469: not from collection
50669: not enough ton
53832: Only wallet can burn tokens
62176: Invalid total supply after burn
62742: non-sequential NFTs
62972: Invalid balance