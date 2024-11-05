# OTC

For more information visit the README in the repo's root folder.

https://github.com/MAYZGitHub/mayz-otc/blob/main/README.md

MAYZ Token Utility: Required for both individual and institutional cases. Individuals need MAYZ tokens to initiate contracts and mint NFTs, and protocols would use MAYZ tokens alongside their tokens 
to create and manage OTC contracts. MAYZ tokens can be retrieved once no tokens are left in the contract.

Naming Conventions: Tokens could follow a standard like "black", "silver", "gold" to represent different amounts, or each protocol could define their own. 
For individuals, NFT names would illustrate what they represent, e.g., "OTC-LEND-1.50M" for 1,500,000 LEND tokens.
Special Considerations:
Multi-Token Representation: Exploring scenarios where OTC tokens could represent more than one type of token, e.g., 1.5M LEND and 2M MIN, offering flexible asset bundling.

OTC Token Flow:

Token Locking: Users deposit tokens into the smart contract.
NFT Issuance: The contract mints an NFT that acts as a key to the deposited tokens.
Trading: The NFT can be traded on secondary markets, representing ownership of the underlying tokens.
Redemption: The holder of the NFT can return it to the contract to unlock the tokens.
Datum Details: The datum plays a crucial role in the OTC process, storing essential information:

Creator details: Enables the retrieval of MAYZ tokens upon completion of the exchange (when someone has traded the NFT for the backed tokens).
Token representation: Specifies the quantity of tokens represented by the NFT.
Token specifics: Includes details about the policy ID and token name of the backed tokens.
Transaction data: Stores other relevant transaction-related information.

Smart Contract Architecture
The current architecture overview includes:

Token Locking Contract: Allows users to lock fungible tokens.
NFT Minting Contract: Mints NFTs representing locked tokens.
Redemption Contract: Handles the exchange of NFTs back to fungible tokens.

Error Handling and Security
Token Redemption: The Plutus validator script will include a check to ensure that the specific OTC NFT is burned in the same transaction that attempts to retrieve the underlying tokens. 
This ensures that only the current holder of the OTC NFT can redeem the locked tokens.
Unauthorized Access Prevention: For creators retrieving their tokens (in case no one has traded the OTC NFT), the Plutus validator will compare the transaction's signature with the signature stored in the datum. 
This ensures that only the original creator can reclaim their tokens if the OTC NFT hasn't been traded.