use aiken/crypto.{ScriptHash}
use cardano/assets.{PolicyId, add, from_asset_list, quantity_of}
use cardano/transaction.{Output, Transaction}
use types.{
  CancelOTC, ClaimOTC, CloseOTC, CreateOTC, OTCDatum, OTCParams, OTCRedeemer,
  UpdateOTCMinADA,
}
use utils.{
  add_lovelace, check_if_otc_nft_is_present_in_inputs,
  check_value_sent_to_signer, check_value_sent_to_wallet, get_otc_from_inputs,
  get_otc_from_outputs, get_protocol_from_inputs_ref, is_signed_by_creator,
  validate_otc_name,
}

// OTC validator function
validator otc(params: OTCParams) {
  spend(
    datum: Option<OTCDatum>,
    redeemer: OTCRedeemer,
    script_hash: ScriptHash,
    transaction: Transaction,
  ) {
    let otc_policy_id = script_hash

    when datum is {
      Some(otcDatum_In) ->
        when redeemer is {
          ClaimOTC ->
            validate_claim(params, otc_policy_id, otcDatum_In, transaction)
          CloseOTC ->
            validate_close(params, otc_policy_id, otcDatum_In, transaction)
          CancelOTC ->
            validate_cancel(params, otc_policy_id, otcDatum_In, transaction)
          UpdateOTCMinADA(new_min_ada) ->
            validate_update_min_ada(
              params,
              otc_policy_id,
              otcDatum_In,
              new_min_ada,
              transaction,
            )
          _ -> False
        }
      None -> False
    }
  }

  mint(redeemer: OTCRedeemer, otc_policy_id: PolicyId, transaction: Transaction) {
    when redeemer is {
      CreateOTC -> validate_create(params, otc_policy_id, transaction)
      CloseOTC | CancelOTC ->
        validate_burn_otc(params, otc_policy_id, transaction)
      _ -> False
    }
  }

  else(_) {
    fail
  }
}

fn validate_create(
  params: OTCParams,
  otc_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  // Get protocol datum from reference input
  expect Some((_, protocolDatum_Ref)) =
    get_protocol_from_inputs_ref(
      transaction,
      params.pp_protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // No existing OTC input should exist for creation
  expect None =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 0)

  // Get the OTC output being created
  expect Some((otc_Out, otcDatum_Out)) =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  let otc_Out_Value_Control =
    [
      // OTC ID token
      Pair(otc_policy_id, [Pair(params.pp_otc_id_tn, 1)]),
      // Underlying tokens
      Pair(
        otcDatum_Out.od_token_policy_id,
        [Pair(otcDatum_Out.od_token_tn, otcDatum_Out.od_token_amount)],
      ),
      // MAYZ deposit
      Pair(
        params.pp_mayz_policy_id,
        [Pair(params.pp_mayz_tn, protocolDatum_Ref.pd_mayz_deposit_requirement)],
      ),
    ]
      |> from_asset_list()
      |> add_lovelace(otcDatum_Out.od_min_ada)

  let otcDatum_Out_Control =
    OTCDatum {
      ..otcDatum_Out,
      od_otc_policy_id: otc_policy_id,
      od_mayz_locked: protocolDatum_Ref.pd_mayz_deposit_requirement,
    }

  and {
    // Minimum ADA validation
    otcDatum_Out.od_min_ada > 0,
    // Both OTC ID and NFT must be minted
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == 1,
    quantity_of(transaction.mint, otc_policy_id, otcDatum_Out.od_otc_tn) == 1,
    // Verify OTC NFT name format
    validate_otc_name(
      otcDatum_Out.od_otc_tn,
      otcDatum_Out.od_token_tn,
      otcDatum_Out.od_token_amount,
    ),
    // Value validations
    otc_Out.value == otc_Out_Value_Control,
    // Datum validations
    otcDatum_Out == otcDatum_Out_Control,
  }
}

fn validate_burn_otc(
  params: OTCParams,
  otc_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  expect Some((_, otcDatum_In)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  and {
    // Both OTC ID and NFT must be burned
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == -1,
    quantity_of(transaction.mint, otc_policy_id, otcDatum_In.od_otc_tn) == -1,
  }
}

fn validate_claim(
  params: OTCParams,
  otc_policy_id: PolicyId,
  otcDatum_In: OTCDatum,
  transaction: Transaction,
) -> Bool {
  // Get input OTC UTXO with tokens
  expect Some((otc_In, _)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)
  // Get output OTC UTXO that will hold MAYZ deposit
  expect Some((otc_Out, otcDatum_Out)) =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  // Control Value for buyer output with tokens
  let buyer_Value_Control =
    [
      Pair(
        otcDatum_In.od_token_policy_id,
        [Pair(otcDatum_In.od_token_tn, otcDatum_In.od_token_amount)],
      ),
    ]
      |> from_asset_list()

  // Control Value: Remove underlying tokens and add OTC NFT
  let otc_Out_Value_Control =
    otc_In.value
      |> add(
          otcDatum_In.od_token_policy_id,
          otcDatum_In.od_token_tn,
          -otcDatum_In.od_token_amount,
        )
      |> add(otc_policy_id, otcDatum_In.od_otc_tn, 1)
  // Control Datum: Must remain unchanged
  let otcDatum_Out_Control = otcDatum_In

  and {
    check_if_otc_nft_is_present_in_inputs(
      transaction,
      otc_policy_id,
      otcDatum_In.od_otc_tn,
    ),
    check_value_sent_to_signer(transaction, buyer_Value_Control),
    // Value validations
    otc_Out.value == otc_Out_Value_Control,
    // Datum validations
    otcDatum_Out == otcDatum_Out_Control,
  }
}

fn validate_close(
  params: OTCParams,
  otc_policy_id: PolicyId,
  otcDatum_In: OTCDatum,
  transaction: Transaction,
) -> Bool {
  // Get input OTC UTXO with MAYZ deposit
  expect Some((_, _)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  // No OTC output should exist after closing
  expect None =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 0)

  // Control Value for creator output with MAYZ deposit
  let creator_Value_Control =
    [
      Pair(
        params.pp_mayz_policy_id,
        [Pair(params.pp_mayz_tn, otcDatum_In.od_mayz_locked)],
      ),
    ]
      |> from_asset_list()
      |> add_lovelace(otcDatum_In.od_min_ada)

  and {
    // Authorization check
    is_signed_by_creator(transaction, otcDatum_In.od_creator),
    // Burn validations
    quantity_of(transaction.mint, otc_policy_id, otcDatum_In.od_otc_tn) == -1,
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == -1,
    // Creator receives MAYZ deposit
    check_value_sent_to_wallet(
      transaction,
      otcDatum_In.od_creator,
      creator_Value_Control,
    ),
  }
}

fn validate_cancel(
  params: OTCParams,
  otc_policy_id: PolicyId,
  otcDatum_In: OTCDatum,
  transaction: Transaction,
) -> Bool {
  // Get input OTC UTXO with all tokens
  expect Some((_, _)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  // No OTC output should exist after canceling
  expect None =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 0)

  // Control Value for creator output with all assets
  let creator_Value_Control =
    [
      Pair(
        params.pp_mayz_policy_id,
        [Pair(params.pp_mayz_tn, otcDatum_In.od_mayz_locked)],
      ),
      Pair(
        otcDatum_In.od_token_policy_id,
        [Pair(otcDatum_In.od_token_tn, otcDatum_In.od_token_amount)],
      ),
    ]
      |> from_asset_list()
      |> add_lovelace(otcDatum_In.od_min_ada)

  and {
    // Authorization check
    is_signed_by_creator(transaction, otcDatum_In.od_creator),
    // Burn validations
    quantity_of(transaction.mint, otc_policy_id, otcDatum_In.od_otc_tn) == -1,
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == -1,
    // Creator receives all assets
    check_value_sent_to_wallet(
      transaction,
      otcDatum_In.od_creator,
      creator_Value_Control,
    ),
  }
}

fn validate_update_min_ada(
  params: OTCParams,
  otc_policy_id: PolicyId,
  otcDatum_In: OTCDatum,
  new_min_ada: Int,
  transaction: Transaction,
) -> Bool {
  // Get input and output OTC UTXOs
  expect Some((otc_In, _)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)
  expect Some((otc_Out, otcDatum_Out)) =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  let otc_Out_Value_Control =
    otc_In.value
      |> add_lovelace(-otcDatum_In.od_min_ada)
      |> add_lovelace(new_min_ada)

  let otcDatum_Out_Control = OTCDatum { ..otcDatum_In, od_min_ada: new_min_ada }

  and {
    // Authorization check
    is_signed_by_creator(transaction, otcDatum_In.od_creator),
    // Minimum ADA validation
    new_min_ada > 0,
    // Value validations
    otc_Out.value == otc_Out_Value_Control,
    // Datum validations
    otcDatum_Out == otcDatum_Out_Control,
  }
}
