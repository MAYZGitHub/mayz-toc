use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference}

// Protocol Types

pub type ProtocolParams {
  pp_protocol_policy_id_tx_out_ref: OutputReference,
  pp_protocol_id_tn: ByteArray,
}

pub type ProtocolDatum {
  pd_admins: List<VerificationKeyHash>,
  pd_token_admin_policy_id: PolicyId,
  pd_mayz_deposit_requirement: Int,
  pd_min_ada: Int,
}

pub type ProtocolRedeemer {
  CreateProtocol
  UpdateProtocolParams
  UpdateProtocolMinADA(Int)
}

// OTC Types

pub type OTCParams {
  pp_protocol_policy_id: PolicyId,
  pp_protocol_id_tn: ByteArray,
  // Protocol ID token name
  pp_otc_id_tn: ByteArray,
  // OTC ID token name
  pp_mayz_policy_id: PolicyId,
  // MAYZ token policy ID
  pp_mayz_tn: ByteArray,
}

pub type OTCDatum {
  // Creator's verification key hash
  od_creator: VerificationKeyHash,
  // Underlying token details
  od_token_policy_id: PolicyId,
  od_token_tn: ByteArray,
  od_token_amount: Int,
  // OTC token details
  od_otc_policy_id: PolicyId,
  od_otc_tn: ByteArray,
  // MAYZ token deposit
  od_mayz_locked: Int,
  // Minimum ADA required
  od_min_ada: Int,
}

pub type OTCRedeemer {
  CreateOTC
  ClaimOTC
  CloseOTC
  CancelOTC
  UpdateOTCMinADA(Int)
}
