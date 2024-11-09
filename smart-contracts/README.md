# MAYZ Trustless OTC Smart Contract - Architecture

## Table of Contents
- [MAYZ Trustless OTC Smart Contract - Architecture](#mayz-trustless-otc-smart-contract---architecture)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Dependencies](#dependencies)
  - [Install](#install)
  - [Smart Contract Components](#smart-contract-components)
    - [Protocol Contract](#protocol-contract)
      - [Parameters](#parameters)
      - [Protocol Datum Structure](#protocol-datum-structure)
        - [Field Descriptions](#field-descriptions)
      - [Authorization Logic](#authorization-logic)
      - [Protocol Redeemers](#protocol-redeemers)
        - [1. CreateProtocol](#1-createprotocol)
        - [2. UpdateProtocolParams](#2-updateprotocolparams)
        - [3. UpdateMinADA](#3-updateminada)
    - [OTC NFT Minting Policy](#otc-nft-minting-policy)
      - [Parameters](#parameters-1)
      - [Minting Policy Logic](#minting-policy-logic)
      - [Minting Policy Redeemers](#minting-policy-redeemers)
        - [1. Mint](#1-mint)
        - [2. Burn](#2-burn)
    - [OTC Contract](#otc-contract)
      - [Parameters](#parameters-2)
      - [OTC Datum Structure](#otc-datum-structure)
        - [Field Descriptions](#field-descriptions-1)
      - [OTC Redeemers](#otc-redeemers)
        - [1. Create](#1-create)
        - [2. Claim](#2-claim)
        - [3. Close](#3-close)
        - [4. Cancel](#4-cancel)
        - [5. UpdateMinADA](#5-updateminada)
  - [Token Flow and Interactions](#token-flow-and-interactions)
    - [Token Standards](#token-standards)
    - [Creation Flow](#creation-flow)
    - [Redemption Flow](#redemption-flow)
    - [Closing Flow](#closing-flow)
    - [Cancellation Flow](#cancellation-flow)
  - [Security Considerations](#security-considerations)
  - [Metadata Handling](#metadata-handling)


## Overview

The MAYZ Trustless OTC Smart Contract architecture consists of three main components written in Aiken v1.1.5:

1. Protocol Contract: Manages protocol parameters and mints Protocol ID tokens. Since we are using Aiken v1.1.5, which supports Plutus V3, we can handle both within the same validator. 
2. OTC Contract: Handles token locking and redemption processes
3. OTC NFT Minting Policy: Dedicated policy for minting unique OTC NFT tokens

### Dependencies
- Aiken v1.1.5
- aiken-lang/stdlib v2.1.0

## Install
```

# Install aikup
npm install -g @aiken-lang/aikup

# Run aikup
aikup

# Add Aiken to your PAHT
export PATH="/home/manuelpadilla/.aiken/bin:$PATH"

# Build the project
aiken build

# Run tests (when you have them)
aiken check

# Format ```
aiken fmt

# Start REPL for testing ```
aiken console

# Generate documentation
aiken docs

# Check Aiken version
aiken --version

```

## Smart Contract Components

### Protocol Contract

#### Parameters
```
type ProtocolParams {
  pp_protocol_policy_id_tx_out_ref: OutputReference,
  pp_protocol_id_tn: ByteArray,
}
```

#### Protocol Datum Structure

```
type ProtocolDatum {
  // List of payment verification key hashes that can perform administrative actions
  pdAdmins: List<VerificationKeyHash>,
  
  // Policy ID of the admin token that can also authorize administrative actions
  pdTokenAdminPolicyID: PolicyId,
  
  // Required amount of $MAYZ tokens to be locked when creating an OTC position
  pdMayzDepositRequirement: Int,
  
  // Minimum ADA required to be present in protocol UTXOs
  pdMinADA: Int
}
```

##### Field Descriptions

1. **pdAdmins** (List<VerificationKeyHash>)
   - Purpose: Stores the list of authorized administrator public key hashes
   - Usage: Controls who can perform protocol administration tasks
   - Validation: Used to verify administrative transactions
   - Type: List of Cardano verification key hashes
   - Note: Administrators can update protocol parameters and minimum ADA requirements

2. **pdTokenAdminPolicyID** (PolicyId)
   - Purpose: Identifies the policy of tokens that grant administrative privileges
   - Usage: Allows token-based authorization for administrative actions
   - Validation: Any transaction containing this admin token can perform admin actions
   - Type: Cardano PolicyId (hash of the minting policy)
   - Note: Provides an alternative to direct wallet-based admin authorization

3. **pdMayzDepositRequirement** (Int)
   - Purpose: Specifies the required amount of $MAYZ tokens for OTC creation
   - Usage: Users must lock this amount when creating an OTC position
   - Validation: Checked during OTC creation transactions
   - Type: Integer representing token quantity
   - Note: $MAYZ tokens are returned to creator after successful OTC completion

4. **pdMinADA** (Int)
   - Purpose: Defines minimum ADA required in protocol UTXOs
   - Usage: Ensures sufficient ADA for transaction fees and UTXO minimum requirements
   - Type: Integer representing lovelace amount
   - Note: Can be updated by administrators based on network conditions

#### Authorization Logic
Administrative actions can be performed in two ways:
1. Direct wallet authorization: Transaction signed by a wallet whose payment verification key hash is in pdAdmins
2. Token-based authorization: Transaction includes a token from pdTokenAdminPolicyID

#### Protocol Redeemers

##### 1. CreateProtocol
- Purpose: Initialize protocol by minting Protocol ID token and creating protocol UTXO
- Transaction Structure:
  * Input: Referenced UTXO from protocol parameters
  * Mint: Protocol ID token (amount: 1)
  * Output: Protocol UTXO with Protocol ID token and Protocol Datum
- Validations:
  * Protocol ID token mint amount must be exactly 1
  * Referenced UTXO must be consumed in the transaction
  * Output must contain valid Protocol Datum with initial parameters
  * Output must contain the Protocol ID token
  * Output must contain minimum ADA specified in Protocol Datum

##### 2. UpdateProtocolParams
- Purpose: Update protocol parameters while maintaining Protocol ID token
- Transaction Structure:
  * Input: Protocol UTXO (identified by Protocol ID token)
  * Output: Updated Protocol UTXO with Protocol ID token
- Validations:
  * Authorization: Must be signed by admin wallet OR include admin token
  * Single valid Protocol UTXO input (containing Protocol ID token)
  * Single valid Protocol UTXO output (containing Protocol ID token)
  * Only allowed parameter updates: pdAdmins, pdTokenAdminPolicyID and pdMayzDepositRequirement fields
  * Must maintain same value (Protocol ID token + ADA) between input/output

##### 3. UpdateMinADA
- Purpose: Update minimum ADA in protocol UTXO
- Transaction Structure:
  * Input: Protocol UTXO (identified by Protocol ID token)
  * Output: Updated Protocol UTXO with Protocol ID token
- Validations:
  * Authorization: Must be signed by admin wallet OR include admin token
  * Single valid Protocol UTXO input (containing Protocol ID token)
  * Single valid Protocol UTXO output (containing Protocol ID token)
  * Only allowed update: minimum ADA field
  * Output must contain updated minimum ADA amount

### OTC NFT Minting Policy

#### Parameters
```
type OTCNFTParams {
  ppOTCValidatorHash: ValidatorHash  // Reference to OTC validator for validation
}
```

#### Minting Policy Logic
The minting policy validates that:
- The OTC validator script is involved in the transaction
- Token name follows the required format

Token Name Format:
```
"OTC-[TOKEN]-[AMOUNT]"
Example: "OTC-LEND-1.50M"
```

#### Minting Policy Redeemers

##### 1. Mint 
- Purpose: Create new OTC NFT token during OTC position creation
- Transaction Structure: [1. Create](#1-create)
- Validations:
  * Single OTC NFT token minted
  * Token name follows correct format
  * Transaction includes output to OTC validator script
  * Token creator signature present
  * Output datum at OTC validator contains correct token details

##### 2. Burn
- Purpose: Burn OTC NFT token during Close or Cancel operations
- Transaction Structure: [3. Close](#3-close) o [4. Cancel](#4-cancel)
- Validations:
  * Single OTC NFT token burned
  * Corresponding OTC validator script input present
  * Proper spend authorization present
  
### OTC Contract

#### Parameters
```
type OTCParams {
  ppProtocolPolicyID: PolicyId
}
```

#### OTC Datum Structure
```
type OTCDatum {
  // Payment verification key hash of the OTC position creator
  odCreator: VerificationKeyHash,
  
  // Policy ID of the underlying tokens to be locked
  odTokenPolicy: PolicyId,
  
  // Token name of the underlying tokens to be locked
  odTokenName: ByteArray,
  
  // Amount of underlying tokens locked in the OTC position
  odTokenAmount: Int,
  
  // Policy ID of the OTC NFT token being minted
  odOTCPolicy: PolicyId,
  
  // Name of the OTC NFT token following naming convention
  odOTCName: ByteArray,
  
  // Amount of $MAYZ Token locked as deposit for this OTC position
  odMAYZLocked: Int,
  
  // Minimum ADA required to be present in the OTC UTXO
  odMinADA: Int
}
```

##### Field Descriptions

1. **odCreator** (VerificationKeyHash)
   - Purpose: Identifies the creator of the OTC position
   - Usage: Used to verify authorization for Close and Cancel operations
   - Validation: Must match transaction signer for administrative actions
   - Type: Cardano verification key hash
   - Note: Only this address can retrieve $MAYZ Token deposit or cancel position

2. **odTokenPolicy** (PolicyId)
   - Purpose: Identifies the policy of the underlying tokens being locked
   - Usage: Used to verify correct tokens during Create and Claim operations
   - Validation: Must match the tokens being locked in Create operation
   - Type: Cardano PolicyId (hash of the minting policy)

3. **odTokenName** (ByteArray)
   - Purpose: Specifies the name of the underlying tokens being locked
   - Usage: Combined with policy ID to uniquely identify locked tokens
   - Validation: Must match the token name of locked assets
   - Type: ByteArray representing token name

4. **odTokenAmount** (Int)
   - Purpose: Specifies the quantity of underlying tokens locked
   - Usage: Ensures correct amount during Create and Claim operations
   - Validation: Must match actual locked token amount
   - Type: Integer representing token quantity

5. **odOTCPolicy** (PolicyId)
   - Purpose: Identifies the policy ID of the OTC NFT token
   - Usage: Used to verify the correct OTC NFT token during operations
   - Validation: Must match the policy ID of minted OTC NFT token
   - Type: Cardano PolicyId

6. **odOTCName** (ByteArray)
   - Purpose: Stores the name of the OTC NFT token
   - Usage: Used to identify and validate the specific OTC NFT token
   - Validation: Must follow naming convention "OTC-[TOKEN]-[AMOUNT]"
   - Type: ByteArray representing token name
   - Example: "OTC-LEND-1.50M"

7. **odMAYZLocked** (Int)
   - Purpose: Records amount of $MAYZ Token locked as deposit
   - Usage: Ensures correct deposit amount is maintained
   - Validation: Must match protocol's required deposit amount
   - Type: Integer representing $MAYZ Token quantity
   - Note: Retrieved by creator after successful completion or cancellation

8. **odMinADA** (Int)
   - Purpose: Defines minimum ADA required in OTC UTXO
   - Usage: Ensures sufficient ADA for transaction fees and UTXO requirements
   - Type: Integer representing lovelace amount
   - Note: Returned to creator along with other assets

#### OTC Redeemers

##### 1. Create
- Purpose: Initialize OTC position by minting tokens and locking assets
- Transaction Structure:
  * Reference Input: Protocol UTXO (for parameter validation)
  * Mint: OTC ID token (amount: 1) and OTC NFT token (amount: 1) via NFT minting policy
  * Output 1: OTC UTXO containing:
    - OTC ID token
    - Underlying tokens
    - $MAYZ Token deposit
    - Minimum ADA
    - Proper OTC datum with minted token details
  * Output 2: OTC NFT token to creator address
- Validations:
  * No existing OTC ID token in inputs
  * Single valid OTC UTXO output with OTC Datum
  * Required $MAYZ Token deposit matches Protocol Datum
  * Underlying token details match redeemer specifications
  * OTC NFT token name follows naming convention
  * All required assets sent to validator address
  * OTC NFT token sent to transaction signer

##### 2. Claim
- Purpose: Redeem underlying tokens using OTC NFT token
- Transaction Structure:
  * Input 1: User UTXO with OTC NFT token
  * Input 2: OTC UTXO (identified by OTC ID token)
  * Output 1: Updated OTC UTXO retaining $MAYZ Token deposit
  * Output 2: Underlying tokens to claimer
- Validations:
  * Single valid OTC input (containing OTC ID token)
  * Single valid OTC output (containing OTC ID token)
  * OTC NFT token present in transaction input
  * Output maintains $MAYZ Token deposit, minimum ADA, and OTC ID token and add the OTC NFT token 
  * Underlying tokens transferred to transaction signer

##### 3. Close
- Purpose: Close completed OTC position and retrieve $MAYZ Token deposit
- Transaction Structure:
  * Input: OTC UTXO (identified by OTC ID token) with OTC NFT token
  * Burn: OTC ID token and OTC NFT token
  * Output: $MAYZ Token and ADA to creator
- Validations:
  * Single valid OTC input (containing OTC ID token)
  * No OTC ID token in outputs
  * OTC NFT token present in input OTC UTXO
  * OTC ID token and OTC NFT token are burned
  * Transaction signed by original creator
  * $MAYZ Token deposit and minimum ADA returned to creator

##### 4. Cancel
- Purpose: Cancel active OTC position and retrieve all assets
- Transaction Structure:
  * Input 1: User UTXO with OTC NFT token
  * Input 2: OTC UTXO (identified by OTC ID token)
  * Burn: OTC ID token and OTC NFT token
  * Output: All assets to creator
- Validations:
  * Single valid OTC input (containing OTC ID token)
  * No OTC ID token in outputs
  * OTC NFT token present in transaction input
  * OTC ID token and OTC NFT token are burned
  * Transaction signed by original creator
  * All assets ($MAYZ Token, underlying tokens, minimum ADA) returned to creator

##### 5. UpdateMinADA
- Purpose: Update minimum ADA in OTC UTXO
- Transaction Structure:
  * Input: OTC UTXO (identified by OTC ID token)
  * Output: Updated OTC UTXO with OTC ID token
- Validations:
  * Authorization: Must be signed by creator wallet
  * Single valid OTC UTXO input (containing OTC ID token)
  * Single valid OTC UTXO output (containing OTC ID token)
  * Only allowed update: minimum ADA field
  * Output must contain updated minimum ADA amount
  
## Token Flow and Interactions

### Token Standards
- OTC NFT Naming Convention: "OTC-[TOKEN]-[AMOUNT]"
  Example: "OTC-LEND-1.50M" for 1,500,000 LEND tokens

### Creation Flow
1. User deposits underlying tokens + MAYZ tokens
2. Contract mints OTC ID and OTC NFT tokens
3. OTC NFT token sent to creator
4. Underlying tokens locked in contract

### Redemption Flow
1. OTC NFT holder initiates claim
2. Contract verifies OTC NFT
3. Underlying tokens released to claimer
4. MAYZ deposit remains locked

### Closing Flow
1. Creator initiates close after successful claim
2. OTC ID and NFT tokens burned
3. MAYZ deposit returned to creator

### Cancellation Flow
1. Creator initiates cancellation
2. OTC ID and NFT tokens burned
3. All locked assets returned to creator

## Security Considerations

1. Token Validation
- Strict verification of token policies
- Amount validation for all token operations
- Proper burning verification

2. Authorization
- Creator-only operations for close/cancel
- Admin-only protocol updates
- Token-based authorization checks

3. Value Preservation
- Input/output value matching
- Minimum ADA requirements
- Proper token allocation

## Metadata Handling

Additional token metadata is included during minting transactions:
- Underlying token details
- Amount representations
- Creator information
- Timestamp data
