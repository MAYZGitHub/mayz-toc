//// Redeemers for the Protocol Contract

use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference}

// Protocol Types

/// Parameters for the Protocol Contract and its Policy ID minting
pub type ProtocolParams {
  /// OutputReference that must be consumed when minting the Protocol ID token
  pp_protocol_policy_id_tx_out_ref: OutputReference,
  /// Protocol ID token name that will be minted
  pp_protocol_id_tn: ByteArray,
}

/// Protocol Datum storing governance and configuration parameters
pub type ProtocolDatum {
  /// List of payment verification key hashes that can perform administrative actions
  pd_admins: List<VerificationKeyHash>,
  /// Policy ID of the admin token that can also authorize administrative actions
  pd_token_admin_policy_id: PolicyId,
  /// MAYZ token policy ID
  pd_mayz_policy_id: PolicyId,
  /// MAYZ token name
  pd_mayz_tn: ByteArray,
  /// Required amount of $MAYZ tokens to be locked when creating an OTC position
  pd_mayz_deposit_requirement: Int,
  /// Minimum ADA required to be present in protocol UTXOs
  pd_min_ada: Int,
}

/// Redeemers for the Protocol Contract
pub type ProtocolRedeemer {
  /// Initialize protocol by minting Protocol ID token
  CreateProtocol
  /// Update protocol parameters while maintaining Protocol ID token
  UpdateProtocolParams
  /// Update minimum ADA requirement for protocol UTXOs
  UpdateProtocolMinADA {
    /// New minimum ADA value
    new_min_ada: Int,
  }
}

// OTC NFT Policy Related Types

/// Parameters for the OTC NFT Minting Policy 
pub type OTCNFTParams {
  /// OutputReference that must be consumed when minting tokens
  pp_otc_nft_policy_id_tx_out_ref: OutputReference,
  /// Reference to OTC validator for validation. It's also the OTC ID PolicyID
  pp_otc_validator_hash: ScriptHash,
  /// Protocol ID policy ID
  pp_protocol_policy_id: PolicyId,
  /// Protocol ID token name
  pp_protocol_id_tn: ByteArray,
  /// OTC ID token name
  pp_otc_id_tn: ByteArray,
}

/// Redeemers for the OTC NFT Minting Policy
pub type NFTRedeemer {
  /// Mint new OTC NFT token during position creation
  MintNFT
  /// Burn OTC NFT token during Close/Cancel
  BurnNFT
}

/// OTC Contract Related Types
pub type OTCParams {
  /// Protocol ID policy ID for reference inputs
  pp_protocol_policy_id: PolicyId,
  // Protocol ID token name
  pp_protocol_id_tn: ByteArray,
  // OTC ID token name
  pp_otc_id_tn: ByteArray,
}

/// Datum for OTC positions storing state and configuration
pub type OTCDatum {
  /// Payment verification key hash of the OTC position creator
  od_creator: VerificationKeyHash,
  /// Policy ID of the underlying tokens to be locked
  od_token_policy_id: PolicyId,
  /// Token name of the underlying tokens to be locked
  od_token_tn: ByteArray,
  /// Amount of underlying tokens locked in the OTC position
  od_token_amount: Int,
  /// Policy ID of the OTC NFT token being minted
  od_otc_nft_policy_id: PolicyId,
  /// Name of the OTC NFT token following naming convention
  od_otc_nft_tn: ByteArray,
  /// MAYZ token policy ID
  od_mayz_policy_id: PolicyId,
  /// MAYZ token name
  od_mayz_tn: ByteArray,
  /// Amount of $MAYZ Token locked as deposit for this OTC position
  od_mayz_locked: Int,
  /// Minimum ADA required to be present in the OTC UTXO
  od_min_ada: Int,
}

/// Redeemers for the OTC Contract
pub type OTCRedeemer {
  /// Create new OTC position and mint OTC ID token
  CreateOTC
  /// Claim underlying tokens using OTC NFT
  ClaimOTC
  /// Close completed position and retrieve MAYZ deposit
  CloseOTC
  /// Cancel active position and retrieve all assets
  CancelOTC
  /// Update minimum ADA requirement for OTC UTXO
  UpdateOTCMinADA {
    /// New minimum ADA value 
    new_min_ada: Int,
  }
}
