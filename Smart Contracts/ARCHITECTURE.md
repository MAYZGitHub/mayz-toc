# OTC

## High level overview

$MAYZ Token Utility: Required for both individual and institutional cases. Individuals need $MAYZ tokens to initiate contracts and mint NFTs, and protocols would use $MAYZ tokens alongside their tokens to create and manage OTC contracts. $MAYZ tokens can be retrieved once no tokens are left in the contract.

Naming Conventions: For individuals, NFT names would illustrate what they represent, e.g., "OTC-LEND-1.50M" for 1,500,000 LEND tokens.

### OTC Token Flow:

* Token Locking: Users deposit tokens into the smart contract.
* NFT Issuance: The contract mints an NFT that acts as a key to the deposited tokens.
* Trading: The NFT can be traded on secondary markets, representing ownership of the underlying tokens.
* Redemption: The holder of the NFT can return it to the contract to unlock the tokens.
* Datum Details: The datum plays a crucial role in the OTC process, storing essential information:
* Creator details: Enables the retrieval of $MAYZ tokens upon completion of the exchange (when someone has traded the NFT for the backed tokens).
* Token representation: Specifies the quantity of tokens represented by the NFT.
* Token specifics: Includes details about the policy ID and token name of the backed tokens.
* Transaction data: Stores other relevant transaction-related information.

### Smart Contract Architecture
The current architecture overview includes:

* Protocol Validator contract: To store important protocol parameters, such as $MAYZ required to mint.
* Token Locking Contract: Allows users to lock fungible tokens.
* NFT Minting Contract: Mints NFTs representing locked tokens.
* Redemption Contract: Handles the exchange of NFTs back to fungible tokens and withdrawal of locked MAYZ.
* ID Token: To store important information about the minted OTC NFT and the underlying locked tokens.

### Error Handling and Security
* Token Redemption: The Plutus validator script will include a check to ensure that the specific OTC NFT is burned in the same transaction that attempts to retrieve the underlying tokens. This ensures that only the current holder of the OTC NFT can redeem the locked tokens.
* Unauthorized Access Prevention: For creators retrieving their tokens (in case no one has traded the OTC NFT), the Plutus validator will compare the transaction's signature with the signature stored in the datum. This ensures that only the original creator can reclaim their tokens if the OTC NFT hasn't been traded.

For more information visit the README in the repo's root folder.

https://github.com/MAYZGitHub/mayz-otc/blob/main/README.md



## 1. Protocol validator (TBC Manu)

...

## 2. Script validator.
This is the actual OTC contract, written in Aiken, it will work with 2 well known Plutus purposes, "mint" and "spend". Since we are using Aiken v1.1.5, which supports Plutus V3, we can handle both within the same validator.
Here's the details:


### Dependencies
* aiken v1.1.5
* aiken-lang/stdlib v2.1.0


### ID token - Datum
The ID token datum must include the following details:

1. OTC token creator wallet (pkh) - PaymentCredential
2. Policy + assetName and amount of FTs to be locked - Value
4. Amount of $MAYZ tokens locked - Value
5. Policy + assetName of the "ID" NFT (where we will save important data) - String
6. minADA - Amount of lovelaces to be required accompanying native tokens in their UTXOs - Value


### Redeemer - Actions
In the redeemer we will pass the desired action for our validator to process, depending on this we will have to evaluate multiple conditions.

#### Create: Mint ID and OTC tokens, locks funds and ID with correct Script Datum, sends out the OTC token.
* Will read Reference UTXO with the Protocol Datum to obtain required info such as $MAYZ required as deposit
* Redeemer will include assetName and value Pair
* OTC Token amount must be +1
* ID Token amount must be +1
* MAYZ included in inputs must match the protocol 
* Locked tokens assetName + value Pair must match redeemer and Datum
* Locked tokens, $MAYZ and ID token must be sent to the validator
* OTC token must be sent to TX signer ??? (Perhaps it's a good idea to check this to avoid scam sites using our contract maliciously?) 


#### Close:  Burning of the OTC and ID tokens. Unlocks MAYZ deposit
* Identify input by locating the ID token
* Validate the correct amount of minADA, OTC token, deposited MAYZ and ID token are included in the inputs
* Insures the ID and OTC tokens are burned in the TX
* Validates that the TX signer is the token creator, by matching the ID datum.
* minADA and the deposited $MAYZ are sent back to the creator


#### Claim:  Claiming if the OTC token for the locked FTs.
* Identify input by locating the ID token
* Output datum must match the ID datum
* Validate the correct amount of minADA, OTC token, locked tokens, deposited MAYZ and ID token are included in the inputs
* OTC, $MAYZ, minADA and ID tokens are sent to the validator
* Locked tokens must be sent to TX signer ??? (Perhaps it's a good idea to check this to avoid scam sites using our contract maliciously?)


#### Cancel: Undo OTC token creation and release of all funds back to the creator.
* Identify input by locating the ID token
* Validate the correct amount of locked tokens, minADA, OTC token, deposited MAYZ and ID token are included in the inputs
* Insures the ID and OTC tokens are burned in the TX
* Validates that the TX signer is the token creator, by matching the ID datum
* minADA, locked tokens and the deposited $MAYZ are sent back to the creator