use cardano/address.{Address, from_script, from_verification_key}
use cardano/assets.{from_asset, merge}
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, OutputReference}
use otc_validator_utils.{
  validate_cancel, validate_claim, validate_close, validate_mintID,
  validate_update_min_ada,
}
use types.{OTCDatum, OTCParams, ProtocolDatum}
use utils.{get_otc_from_outputs, mock_transaction}

type TestAssets {
  // Policy IDs
  protocol_policy_id: ByteArray,
  otc_validator_hash: ByteArray,
  otc_nft_policy_id: ByteArray,
  token_admin_policy_id: ByteArray,
  mayz_policy_id: ByteArray,
  token_policy_id: ByteArray,
  // Token Names  
  protocol_id_tn: ByteArray,
  otc_id_tn: ByteArray,
  mayz_tn: ByteArray,
  token_tn: ByteArray,
  otc_nft_tn: ByteArray,
  // Addresses
  creator_pubkey: ByteArray,
  // Values
  min_ada: Int,
  mayz_deposit: Int,
  token_amount: Int,
  mayz_locked: Int,
}

fn test_assets() -> TestAssets {
  TestAssets {
    // Policy IDs 
    protocol_policy_id: #"2222222222222222222222222222222222222222222222222222222222222222",
    otc_validator_hash: #"1111111111111111111111111111111111111111111111111111111111111111",
    otc_nft_policy_id: #"4444444444444444444444444444444444444444444444444444444444444444",
    token_admin_policy_id: #"0000000000000000000000000000000000000000000000000000000000000000",
    mayz_policy_id: #"5555555555555555555555555555555555555555555555555555555555555555",
    token_policy_id: #"3333333333333333333333333333333333333333333333333333333333333333",
    // Token Names
    protocol_id_tn: #"504f4c494359",
    // "POLICY" in hex
    otc_id_tn: #"4f5443",
    // "OTC" in hex
    mayz_tn: #"4d41595a",
    // "MAYZ" in hex
    token_tn: #"544f4b454e",
    // "TOKEN" in hex
    otc_nft_tn: #"4f54432d544f4b454e2d31303030303030",
    // "OTC-TOKEN-1000000" in hex
    // Addresses
    creator_pubkey: #"deadbeef",
    // Values
    min_ada: 2000000,
    mayz_deposit: 100,
    token_amount: 1000000,
    mayz_locked: 100,
  }
}

fn mock_otc_params(assets: TestAssets) -> OTCParams {
  OTCParams {
    pp_protocol_policy_id: assets.protocol_policy_id,
    pp_protocol_id_tn: assets.protocol_id_tn,
    pp_otc_id_tn: assets.otc_id_tn,
  }
}

fn mock_creator_address(assets: TestAssets) -> Address {
  from_verification_key(assets.creator_pubkey)
}

fn mock_protocol_datum(assets: TestAssets) -> ProtocolDatum {
  ProtocolDatum {
    pd_admins: [assets.creator_pubkey],
    pd_token_admin_policy_id: assets.token_admin_policy_id,
    pd_mayz_policy_id: assets.mayz_policy_id,
    pd_mayz_tn: assets.mayz_tn,
    pd_mayz_deposit_requirement: assets.mayz_deposit,
    pd_min_ada: assets.min_ada,
  }
}

fn mock_otc_datum(assets: TestAssets) -> OTCDatum {
  OTCDatum {
    od_creator: assets.creator_pubkey,
    od_token_policy_id: assets.token_policy_id,
    od_token_tn: assets.token_tn,
    od_token_amount: assets.token_amount,
    od_otc_nft_policy_id: assets.otc_nft_policy_id,
    od_otc_nft_tn: assets.otc_nft_tn,
    od_mayz_policy_id: assets.mayz_policy_id,
    od_mayz_tn: assets.mayz_tn,
    od_mayz_locked: assets.mayz_locked,
    od_min_ada: assets.min_ada,
  }
}

test create_otc() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create protocol reference input with min ADA 
  let protocol_ref =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: protocol_validator_address,
        value: merge(
          from_asset(params.pp_protocol_policy_id, params.pp_protocol_id_tn, 1),
          from_asset(#"", #"", protocol_datum.pd_min_ada),
        ),
        datum: InlineDatum(protocol_datum),
        reference_script: None,
      },
    }

  // Create OTC output with all required assets
  let otc_output =
    Output {
      address: otc_validator_address,
      value: merge(
        merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(#"", #"", datum.od_min_ada),
        ),
      ),
      datum: InlineDatum(datum),
      reference_script: None,
    }

  // Create output sending tokens to claimer
  let token_output =
    Output {
      address: mock_creator_address(assets),
      value: from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
      datum: NoDatum,
      reference_script: None,
    }

  // Mint both tokens
  let mint_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
    )

  let transaction =
    mock_transaction(
      [protocol_ref],
      [],
      [otc_output, token_output],
      mint_value,
      [datum.od_creator],
    )

  validate_mintID(params, otc_policy_id, transaction) == True
}

test claim_otc() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  //   let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  //   let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with tokens and datum
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create OTC NFT input required for claiming
  let otc_nft_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 1 },
      output: Output {
        address: mock_creator_address(assets),
        value: from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
        datum: NoDatum,
        reference_script: None,
      },
    }

  // Create output OTC UTXO with remaining assets
  let otc_output =
    Output {
      address: otc_validator_address,
      value: merge(
        merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
        ),
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(#"", #"", datum.od_min_ada),
        ),
      ),
      datum: InlineDatum(datum),
      reference_script: None,
    }

  // Create output sending tokens to claimer
  let token_output =
    Output {
      address: mock_creator_address(assets),
      value: from_asset(
        datum.od_token_policy_id,
        datum.od_token_tn,
        datum.od_token_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [otc_input, otc_nft_input],
      [otc_output, token_output],
      from_asset(#"", #"", 0),
      [datum.od_creator],
    )

  validate_claim(params, otc_policy_id, datum, transaction) == True
}

test close_otc() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  //   let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  //   let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with MAYZ deposit
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output returning MAYZ deposit to creator
  let creator_output =
    Output {
      address: mock_creator_address(assets),
      value: merge(
        from_asset(
          datum.od_mayz_policy_id,
          datum.od_mayz_tn,
          datum.od_mayz_locked,
        ),
        from_asset(#"", #"", datum.od_min_ada),
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Burn both tokens
  let burn_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, -1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, -1),
    )

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  validate_close(params, otc_policy_id, datum, transaction) == True
}

test cancel_otc() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  //   let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  //   let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with all tokens
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
          ),
          merge(
            merge(
              from_asset(
                datum.od_mayz_policy_id,
                datum.od_mayz_tn,
                datum.od_mayz_locked,
              ),
              from_asset(
                datum.od_token_policy_id,
                datum.od_token_tn,
                datum.od_token_amount,
              ),
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output returning all assets to creator
  let creator_output =
    Output {
      address: mock_creator_address(assets),
      value: merge(
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        from_asset(#"", #"", datum.od_min_ada),
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Burn both tokens
  let burn_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, -1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, -1),
    )

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  validate_cancel(params, otc_policy_id, datum, transaction) == True
}

test update_otc_min_ada() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_validator_address = from_script(otc_policy_id)
  let datum = mock_otc_datum(assets)
  let new_min_ada = 3000000

  // Create input OTC UTXO with old min ADA
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output OTC UTXO with new min ADA
  let otc_output =
    Output {
      address: otc_validator_address,
      value: merge(
        merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(#"", #"", new_min_ada),
        ),
      ),
      datum: InlineDatum(OTCDatum { ..datum, od_min_ada: new_min_ada }),
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [otc_output],
      from_asset(#"", #"", 0),
      [datum.od_creator],
    )

  validate_update_min_ada(
    params,
    otc_policy_id,
    datum,
    new_min_ada,
    transaction,
  ) == True
}

test invalid_claim() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_validator_address = from_script(otc_policy_id)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with tokens and datum
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create invalid output trying to steal tokens without maintaining OTC state
  let invalid_output =
    Output {
      address: mock_creator_address(assets),
      value: from_asset(
        datum.od_token_policy_id,
        datum.od_token_tn,
        datum.od_token_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [invalid_output],
      from_asset(#"", #"", 0),
      [datum.od_creator],
    )

  // Test that get_otc_from_outputs returns None since there's no valid OTC output
  let result =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)
  // Should return True because:
  // 1. get_otc_from_outputs returns None
  // 2. This proves the validator correctly identifies missing OTC output
  when result is {
    Some(_) -> False
    None -> True
  }
}

test invalid_close() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  //   let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  //   let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  //   let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with MAYZ deposit but missing OTC NFT
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output returning MAYZ deposit to creator
  let creator_output =
    Output {
      address: mock_creator_address(assets),
      value: merge(
        from_asset(
          datum.od_mayz_policy_id,
          datum.od_mayz_tn,
          datum.od_mayz_locked,
        ),
        from_asset(#"", #"", datum.od_min_ada),
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Try to burn just OTC ID token without OTC NFT
  let burn_value = from_asset(otc_policy_id, params.pp_otc_id_tn, -1)

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  // Should fail because:
  // - Missing OTC NFT token in input
  // - Not burning OTC NFT token
  validate_close(params, otc_policy_id, datum, transaction) == False
}

test invalid_cancel() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  //   let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  //   let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  //   let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO with tokens but missing OTC NFT
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output trying to return assets without proper burning
  let creator_output =
    Output {
      address: mock_creator_address(assets),
      value: merge(
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        from_asset(#"", #"", datum.od_min_ada),
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Try to burn just OTC ID token without OTC NFT
  let burn_value = from_asset(otc_policy_id, params.pp_otc_id_tn, -1)

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  // Should fail because:
  // - Missing OTC NFT token in input
  // - Not burning OTC NFT token
  validate_cancel(params, otc_policy_id, datum, transaction) == False
}

test unauthorized_update_min_ada() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_validator_address = from_script(otc_policy_id)
  let datum = mock_otc_datum(assets)
  let new_min_ada = 3000000

  // Create input OTC UTXO
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output with updated min ADA
  let otc_output =
    Output {
      address: otc_validator_address,
      value: merge(
        merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(#"", #"", new_min_ada),
        ),
      ),
      datum: InlineDatum(OTCDatum { ..datum, od_min_ada: new_min_ada }),
      reference_script: None,
    }

  // Transaction without creator signature!
  let transaction =
    mock_transaction([], [otc_input], [otc_output], from_asset(#"", #"", 0), [])

  // Empty signatories list - no authorization
  // Should fail because:
  // - Missing creator signature authorization
  validate_update_min_ada(
    params,
    otc_policy_id,
    datum,
    new_min_ada,
    transaction,
  ) == False
}

test invalid_update_min_ada_value() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_validator_address = from_script(otc_policy_id)
  let datum = mock_otc_datum(assets)
  let new_min_ada = 0

  // Invalid - must be positive
  // Create input OTC UTXO
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(
              datum.od_token_policy_id,
              datum.od_token_tn,
              datum.od_token_amount,
            ),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output with invalid min ADA
  let otc_output =
    Output {
      address: otc_validator_address,
      value: merge(
        merge(
          from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
          from_asset(
            datum.od_token_policy_id,
            datum.od_token_tn,
            datum.od_token_amount,
          ),
        ),
        merge(
          from_asset(
            datum.od_mayz_policy_id,
            datum.od_mayz_tn,
            datum.od_mayz_locked,
          ),
          from_asset(#"", #"", new_min_ada),
        ),
      ),
      datum: InlineDatum(OTCDatum { ..datum, od_min_ada: new_min_ada }),
      reference_script: None,
    }

  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [otc_output],
      from_asset(#"", #"", 0),
      [datum.od_creator],
    )

  // Should fail because:
  // - New min ADA value is invalid (zero)
  validate_update_min_ada(
    params,
    otc_policy_id,
    datum,
    new_min_ada,
    transaction,
  ) == False
}

test invalid_creator_close() {
  let assets = test_assets()
  let params = mock_otc_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(otc_policy_id)
  let datum = mock_otc_datum(assets)
  // Create input OTC UTXO with MAYZ deposit
  let otc_input =
    Input {
      output_reference: OutputReference { transaction_id: #"", output_index: 0 },
      output: Output {
        address: otc_validator_address,
        value: merge(
          merge(
            from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
            from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
          ),
          merge(
            from_asset(
              datum.od_mayz_policy_id,
              datum.od_mayz_tn,
              datum.od_mayz_locked,
            ),
            from_asset(#"", #"", datum.od_min_ada),
          ),
        ),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  // Create output trying to return MAYZ deposit
  let malicious_output =
    Output {
      address: mock_creator_address(assets),
      value: merge(
        from_asset(
          datum.od_mayz_policy_id,
          datum.od_mayz_tn,
          datum.od_mayz_locked,
        ),
        from_asset(#"", #"", datum.od_min_ada),
      ),
      datum: NoDatum,
      reference_script: None,
    }

  // Burn tokens
  let burn_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, -1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, -1),
    )

  // Transaction signed by different wallet!
  let wrong_signer = #"beefdead"
  let transaction =
    mock_transaction(
      [],
      [otc_input],
      [malicious_output],
      burn_value,
      [wrong_signer],
    )

  // Wrong signature
  // Should fail because:
  // - Transaction not signed by original creator
  validate_close(params, otc_policy_id, datum, transaction) == False
}
