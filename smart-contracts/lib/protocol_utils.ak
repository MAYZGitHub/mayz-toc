use aiken/collection/list
use cardano/assets.{PolicyId, from_asset_list, quantity_of}
use cardano/transaction.{Input, Output, Transaction}
use types.{ProtocolDatum, ProtocolParams}
use utils.{
  add_lovelace, get_protocol_from_inputs, get_protocol_from_outputs,
  is_admin_auth, validate_protocol_params,
}

/// Validates the creation of a new protocol instance
/// This includes minting the Protocol ID token and setting up initial parameters
pub fn validate_create(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  // Verify that referenced UTXO is consumed (ensures policy uniqueness)
  expect Some(_reference_input) =
    list.find(
      transaction.inputs,
      fn(input) {
        input.output_reference == params.pp_protocol_policy_id_tx_out_ref
      },
    )

  // No protocol input should exist during initial creation
  expect None =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      0,
    )

  // Exactly one protocol output must be created
  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Control values for validation
  let protocolDatum_Out_Control = protocolDatum_Out
  let protocol_Out_Value_Control =
    [Pair(protocol_policy_id, [Pair(params.pp_protocol_id_tn, 1)])]
      |> from_asset_list()
      |> add_lovelace(protocolDatum_Out.pd_min_ada)

  and {
    // Must mint exactly one Protocol ID token
    quantity_of(transaction.mint, protocol_policy_id, params.pp_protocol_id_tn) == 1,
    // Initial protocol parameters must be valid
    validate_protocol_params(protocolDatum_Out),
    // Output value must match expected control value
    protocol_Out.value == protocol_Out_Value_Control,
    // Output datum must match control datum
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}

/// Validates updates to protocol parameters
/// Only allows updating admin list, token admin policy, and MAYZ deposit requirement
pub fn validate_update_params(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  protocolDatum_In: ProtocolDatum,
  transaction: Transaction,
) -> Bool {
  // Must have exactly one protocol input
  expect Some((protocol_In, _)) =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Must have exactly one protocol output
  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Verify admin authorization
  let authorized = is_admin_auth(transaction, protocolDatum_In)

  // Control values - can update parameters but not min_ada
  let protocolDatum_Out_Control =
    ProtocolDatum {
      ..protocolDatum_Out,
      pd_min_ada: protocolDatum_In.pd_min_ada,
    }
  // Value must remain unchanged
  let protocol_Out_Value_Control = protocol_In.value

  and {
    authorized,
    // New parameters must be valid
    validate_protocol_params(protocolDatum_Out),
    // Output value must match input value
    protocol_Out.value == protocol_Out_Value_Control,
    // Output datum must match control datum
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}

/// Validates updates to minimum ADA requirement
pub fn validate_update_min_ada(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  protocolDatum_In: ProtocolDatum,
  new_min_ada: Int,
  transaction: Transaction,
) -> Bool {
  // Must have exactly one protocol input
  expect Some((protocol_In, _)) =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Must have exactly one protocol output
  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Verify admin authorization
  let authorized = is_admin_auth(transaction, protocolDatum_In)

  // Control values - can only update min_ada
  let protocolDatum_Out_Control =
    ProtocolDatum { ..protocolDatum_In, pd_min_ada: new_min_ada }

  // Update ADA amount in value
  let protocol_Out_Value_Control =
    protocol_In.value
      |> add_lovelace(-protocolDatum_In.pd_min_ada + new_min_ada)

  and {
    authorized,
    // Parameters must remain valid
    validate_protocol_params(protocolDatum_Out),
    // Output value must match control with updated ADA
    protocol_Out.value == protocol_Out_Value_Control,
    // Output datum must match control
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}
