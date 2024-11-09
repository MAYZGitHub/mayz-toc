use aiken/collection/list
use aiken/crypto.{ScriptHash}
use cardano/assets.{PolicyId, from_asset_list, quantity_of}
use cardano/transaction.{Input, Output, Transaction}
use types.{
  CreateProtocol, ProtocolDatum, ProtocolParams, ProtocolRedeemer,
  UpdateProtocolMinADA, UpdateProtocolParams,
}
use utils.{
  add_lovelace, get_protocol_from_inputs, get_protocol_from_outputs,
  is_admin_auth, validate_protocol_params,
}

// Protocol validator function
validator protocol(params: ProtocolParams) {
  spend(
    datum: Option<ProtocolDatum>,
    redeemer: ProtocolRedeemer,
    script_hash: ScriptHash,
    transaction: Transaction,
  ) {
    let protocol_policy_id = script_hash

    when datum is {
      Some(protocolDatum_In) ->
        when redeemer is {
          UpdateProtocolParams ->
            validate_update_params(
              params,
              protocol_policy_id,
              protocolDatum_In,
              transaction,
            )
          UpdateProtocolMinADA(new_min_ada) ->
            validate_update_min_ada(
              params,
              protocol_policy_id,
              protocolDatum_In,
              new_min_ada,
              transaction,
            )
          _ -> False
        }
      None -> False
    }
  }

  mint(
    redeemer: ProtocolRedeemer,
    protocol_policy_id: PolicyId,
    transaction: Transaction,
  ) {
    when redeemer is {
      CreateProtocol -> validate_create(params, protocol_policy_id, transaction)
      _ -> False
    }
  }

  else(_) {
    fail
  }
}

fn validate_create(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  // Verify that referenced UTXO is consumed
  expect Some(_reference_input) =
    list.find(
      transaction.inputs,
      fn(protocol_In) {
        protocol_In.output_reference == params.pp_protocol_policy_id_tx_out_ref
      },
    )

  // No protocol protocol_In should exist for minting
  expect None =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      0,
    )
  // Exactly one protocol output should exist
  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  let protocolDatum_Out_Control = protocolDatum_Out
  let protocol_Out_Value_Control =
    [Pair(protocol_policy_id, [Pair(params.pp_protocol_id_tn, 1)])]
      |> from_asset_list()
      |> add_lovelace(protocolDatum_Out.pd_min_ada)

  and {
    // Verify Protocol ID token mint amount is 1
    quantity_of(transaction.mint, protocol_policy_id, params.pp_protocol_id_tn) == 1,
    // Initial parameters must be valid
    validate_protocol_params(protocolDatum_Out),
    // Protocol output value must match control
    protocol_Out.value == protocol_Out_Value_Control,
    // Protocol datum must match control
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}

// Updated validation functions with proper value and datum checks
fn validate_update_params(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  protocolDatum_In: ProtocolDatum,
  transaction: Transaction,
) -> Bool {
  expect Some((protocol_In, _)) =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  let authorized = is_admin_auth(transaction, protocolDatum_In)

  // Protocol Datum Out can change but not the min_ada
  let protocolDatum_Out_Control =
    ProtocolDatum {
      ..protocolDatum_Out,
      pd_min_ada: protocolDatum_In.pd_min_ada,
    }
  // Protocol Value Out must be the same as Protocol Value In
  let protocol_Out_Value_Control = protocol_In.value

  and {
    authorized,
    // Fields that can change according to architecture:
    validate_protocol_params(protocolDatum_Out),
    // Protocol output value must match control
    protocol_Out.value == protocol_Out_Value_Control,
    // Protocol datum must match control
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}

fn validate_update_min_ada(
  params: ProtocolParams,
  protocol_policy_id: PolicyId,
  protocolDatum_In: ProtocolDatum,
  new_min_ada: Int,
  transaction: Transaction,
) -> Bool {
  expect Some((protocol_In, _)) =
    get_protocol_from_inputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  expect Some((protocol_Out, protocolDatum_Out)) =
    get_protocol_from_outputs(
      transaction,
      protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  let authorized = is_admin_auth(transaction, protocolDatum_In)

  // Protocol Datum Out can change only the min_ada
  let protocolDatum_Out_Control =
    ProtocolDatum { ..protocolDatum_In, pd_min_ada: new_min_ada }
  // Protocol Value Out must be the same as Protocol Value In with the new ADA
  let protocol_Out_Value_Control =
    protocol_In.value
      |> add_lovelace(-protocolDatum_In.pd_min_ada)
      |> add_lovelace(new_min_ada)

  and {
    authorized,
    // Fields that can change according to architecture:
    validate_protocol_params(protocolDatum_Out),
    // Protocol output value must match control
    protocol_Out.value == protocol_Out_Value_Control,
    // Protocol datum must match control
    protocolDatum_Out == protocolDatum_Out_Control,
  }
}
