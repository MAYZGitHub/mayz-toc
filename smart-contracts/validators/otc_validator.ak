use aiken/crypto.{ScriptHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use otc_validator_utils.{
  validate_burnID, validate_cancel, validate_claim, validate_close,
  validate_mintID, validate_update_min_ada,
}
use types.{
  CancelOTC, ClaimOTC, CloseOTC, CreateOTC, OTCDatum, OTCParams, OTCRedeemer,
  UpdateOTCMinADA,
}

/// OTC validator script
/// Handles creation, claiming, closing and cancellation of OTC positions
validator otc(params: OTCParams) {
  spend(
    datum: Option<OTCDatum>,
    redeemer: OTCRedeemer,
    script_hash: ScriptHash,
    transaction: Transaction,
  ) {
    let otc_validator_hash = script_hash

    when datum is {
      Some(otcDatum_In) ->
        when redeemer is {
          ClaimOTC ->
            validate_claim(params, otc_validator_hash, otcDatum_In, transaction)
          CloseOTC ->
            validate_close(params, otc_validator_hash, otcDatum_In, transaction)
          CancelOTC ->
            validate_cancel(
              params,
              otc_validator_hash,
              otcDatum_In,
              transaction,
            )
          UpdateOTCMinADA { new_min_ada } ->
            validate_update_min_ada(
              params,
              otc_validator_hash,
              otcDatum_In,
              new_min_ada,
              transaction,
            )
          CreateOTC -> False
        }
      None -> False
    }
  }

  mint(redeemer: OTCRedeemer, otc_policy_id: PolicyId, transaction: Transaction) {
    when redeemer is {
      CreateOTC -> validate_mintID(params, otc_policy_id, transaction)
      CloseOTC | CancelOTC ->
        validate_burnID(params, otc_policy_id, transaction)
      _ -> False
    }
  }

  else(_) {
    fail
  }
}
