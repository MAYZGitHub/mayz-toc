use aiken/fuzz
use cardano/address.{Address, from_script, from_verification_key}
use cardano/assets.{from_asset, merge}
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, OutputReference}
use protocol_utils.{
  validate_create, validate_update_min_ada, validate_update_params,
}
use types.{ProtocolDatum, ProtocolParams}
use utils.{mock_transaction}

type TestAssets {
  // Policy IDs
  protocol_policy_id: ByteArray,
  token_admin_policy_id: ByteArray,
  mayz_policy_id: ByteArray,
  // Token Names
  protocol_id_tn: ByteArray,
  mayz_tn: ByteArray,
  // Addresses
  admin_pubkey: ByteArray,
  // Reference data
  protocol_policy_id_tx_out_ref: OutputReference,
  // Values
  min_ada: Int,
  mayz_deposit: Int,
}

fn test_assets() -> TestAssets {
  TestAssets {
    // Policy IDs 
    protocol_policy_id: #"2222222222222222222222222222222222222222222222222222222222222222",
    token_admin_policy_id: #"0000000000000000000000000000000000000000000000000000000000000000",
    mayz_policy_id: #"5555555555555555555555555555555555555555555555555555555555555555",
    // Token Names
    protocol_id_tn: #"504f4c494359",
    // "POLICY" in hex
    mayz_tn: #"4d41595a",
    // "MAYZ" in hex
    // Addresses
    admin_pubkey: #"deadbeef",
    // Reference data
    protocol_policy_id_tx_out_ref: OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    },
    // Values
    min_ada: 2000000,
    mayz_deposit: 100,
  }
}

fn mock_protocol_params(assets: TestAssets) -> ProtocolParams {
  ProtocolParams {
    pp_protocol_policy_id_tx_out_ref: assets.protocol_policy_id_tx_out_ref,
    pp_protocol_id_tn: assets.protocol_id_tn,
  }
}

fn mock_protocol_datum(assets: TestAssets) -> ProtocolDatum {
  ProtocolDatum {
    pd_admins: [assets.admin_pubkey],
    pd_token_admin_policy_id: assets.token_admin_policy_id,
    pd_mayz_policy_id: assets.mayz_policy_id,
    pd_mayz_tn: assets.mayz_tn,
    pd_mayz_deposit_requirement: assets.mayz_deposit,
    pd_min_ada: assets.min_ada,
  }
}

fn mock_admin_address(assets: TestAssets) -> Address {
  from_verification_key(assets.admin_pubkey)
}

test create_protocol() {
  let assets = test_assets()
  let params = mock_protocol_params(assets)
  let protocol_policy_id = assets.protocol_policy_id
  let protocol_validator_address = from_script(protocol_policy_id)
  let datum = mock_protocol_datum(assets)

  // Create reference input that must be consumed
  let ref_input =
    Input {
      output_reference: params.pp_protocol_policy_id_tx_out_ref,
      output: Output {
        address: mock_admin_address(assets),
        value: from_asset(#"", #"", assets.min_ada),
        datum: NoDatum,
        reference_script: None,
      },
    }

  // Create protocol output with minted token
  let protocol_output =
    Output {
      address: protocol_validator_address,
      value: merge(
        from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
        from_asset(#"", #"", datum.pd_min_ada),
      ),
      datum: InlineDatum(datum),
      reference_script: None,
    }

  // Mint protocol ID token
  let mint_value = from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1)

  let transaction =
    mock_transaction([], [ref_input], [protocol_output], mint_value, [])

  validate_create(params, protocol_policy_id, transaction) == True
}

// Create a fuzzer that generates TestAssets
fn generate_protocol_components_fuzzer() -> Fuzzer<
  (
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    (ByteArray, Int),
    Int,
    Int,
  ),
> {
  fuzz.map9(
    fuzz.bytearray_fixed(32),
    // protocol_policy_id 
    fuzz.bytearray_fixed(32),
    // token_admin_policy_id
    fuzz.bytearray_fixed(32),
    // mayz_policy_id
    fuzz.bytearray_fixed(5),
    // protocol_id_tn
    fuzz.bytearray_fixed(5),
    // mayz_tn 
    fuzz.bytearray_fixed(32),
    // admin_pubkey
    // For reference parts just as a tuple
    fuzz.map2(
      fuzz.bytearray_fixed(32),
      fuzz.int_between(0, 10),
      fn(tx_id, ix) { (tx_id, ix) },
    ),
    fuzz.int_between(1, 1_000_000),
    // min_ada
    fuzz.int_between(1, 1_000),
    // mayz_deposit
    fn(p1, p2, p3, p4, p5, p6, ref_parts, p8, p9) {
      (p1, p2, p3, p4, p5, p6, ref_parts, p8, p9)
    },
  )
}

test prop_validate_create_protocol(
  components: (
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    ByteArray,
    (ByteArray, Int),
    Int,
    Int,
  ) via generate_protocol_components_fuzzer(),
) {
  let (
    protocol_policy_id,
    token_admin_policy_id,
    mayz_policy_id,
    protocol_id_tn,
    mayz_tn,
    admin_pubkey,
    (tx_id, output_idx),
    // Destructure tuple for reference parts
    min_ada,
    mayz_deposit,
  ) = components

  // Create OutputReference from tuple components
  let output_ref =
    OutputReference { transaction_id: tx_id, output_index: output_idx }

  // Create TestAssets from the components
  let assets =
    TestAssets {
      protocol_policy_id,
      token_admin_policy_id,
      mayz_policy_id,
      protocol_id_tn,
      mayz_tn,
      admin_pubkey,
      protocol_policy_id_tx_out_ref: output_ref,
      min_ada,
      mayz_deposit,
    }
  let params = mock_protocol_params(assets)
  let protocol_policy_id = assets.protocol_policy_id
  let protocol_validator_address = from_script(protocol_policy_id)
  let datum = mock_protocol_datum(assets)

  // Create reference input that must be consumed
  let ref_input =
    Input {
      output_reference: params.pp_protocol_policy_id_tx_out_ref,
      output: Output {
        address: mock_admin_address(assets),
        value: from_asset(#"", #"", assets.min_ada),
        datum: NoDatum,
        reference_script: None,
      },
    }

  // Create protocol output with minted token
  let protocol_output =
    Output {
      address: protocol_validator_address,
      value: merge(
        from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
        from_asset(#"", #"", datum.pd_min_ada),
      ),
      datum: InlineDatum(datum),
      reference_script: None,
    }

  // Mint protocol ID token
  let mint_value = from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1)

  let transaction =
    mock_transaction([], [ref_input], [protocol_output], mint_value, [])

  let is_valid = validate_create(params, protocol_policy_id, transaction)

  trace @"assets": assets
  trace @"transaction": transaction
  trace @"is_valid": is_valid

  expect is_valid == True
}

test update_protocol_params() {
  let assets = test_assets()
  let params = mock_protocol_params(assets)
  let protocol_policy_id = assets.protocol_policy_id
  let protocol_validator_address = from_script(protocol_policy_id)
  let old_datum = mock_protocol_datum(assets)

  // Create new datum with updated MAYZ deposit requirement
  let new_datum =
    ProtocolDatum { ..old_datum, pd_mayz_deposit_requirement: 200 }

  // Create input with old datum
  let protocol_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: protocol_validator_address,
        value: merge(
          from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
          from_asset(#"", #"", old_datum.pd_min_ada),
        ),
        datum: InlineDatum(old_datum),
        reference_script: None,
      },
    }

  // Create output with new datum
  let protocol_output =
    Output {
      address: protocol_validator_address,
      value: merge(
        from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
        from_asset(#"", #"", old_datum.pd_min_ada),
      ),
      datum: InlineDatum(new_datum),
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [protocol_input],
      [protocol_output],
      from_asset(#"", #"", 0),
      [assets.admin_pubkey],
    )

  validate_update_params(params, protocol_policy_id, old_datum, transaction) == True
}

test update_protocol_min_ada() {
  let assets = test_assets()
  let params = mock_protocol_params(assets)
  let protocol_policy_id = assets.protocol_policy_id
  let protocol_validator_address = from_script(protocol_policy_id)
  let old_datum = mock_protocol_datum(assets)
  let new_min_ada = 3000000

  // Create new datum with updated min ADA
  let new_datum = ProtocolDatum { ..old_datum, pd_min_ada: new_min_ada }

  // Create input with old datum and value 
  let protocol_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: protocol_validator_address,
        value: merge(
          from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
          from_asset(#"", #"", old_datum.pd_min_ada),
        ),
        datum: InlineDatum(old_datum),
        reference_script: None,
      },
    }

  // Create output with new datum and updated ADA
  let protocol_output =
    Output {
      address: protocol_validator_address,
      value: merge(
        from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
        from_asset(#"", #"", new_min_ada),
      ),
      datum: InlineDatum(new_datum),
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [protocol_input],
      [protocol_output],
      from_asset(#"", #"", 0),
      [assets.admin_pubkey],
    )

  validate_update_min_ada(
    params,
    protocol_policy_id,
    old_datum,
    new_min_ada,
    transaction,
  ) == True
}

test invalid_admin_auth() {
  let assets = test_assets()
  let params = mock_protocol_params(assets)
  let protocol_policy_id = assets.protocol_policy_id
  let protocol_validator_address = from_script(protocol_policy_id)
  let old_datum = mock_protocol_datum(assets)
  let new_min_ada = 3000000

  // Create new datum with updated min ADA
  let new_datum = ProtocolDatum { ..old_datum, pd_min_ada: new_min_ada }

  // Create input with old datum
  let protocol_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: protocol_validator_address,
        value: merge(
          from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
          from_asset(#"", #"", old_datum.pd_min_ada),
        ),
        datum: InlineDatum(old_datum),
        reference_script: None,
      },
    }

  // Create output with new datum and updated ADA
  let protocol_output =
    Output {
      address: protocol_validator_address,
      value: merge(
        from_asset(protocol_policy_id, params.pp_protocol_id_tn, 1),
        from_asset(#"", #"", new_min_ada),
      ),
      datum: InlineDatum(new_datum),
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [protocol_input],
      [protocol_output],
      from_asset(#"", #"", 0),
      [],
    )

  // No admin signature!
  validate_update_min_ada(
    params,
    protocol_policy_id,
    old_datum,
    new_min_ada,
    transaction,
  ) == False
}
