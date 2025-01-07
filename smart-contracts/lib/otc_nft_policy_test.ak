use cardano/address.{Address, from_script, from_verification_key}
use cardano/assets.{from_asset, merge}
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, OutputReference}
use otc_nft_policy_utils.{validate_burnNFT, validate_mintNFT}
use types.{OTCDatum, OTCNFTParams, ProtocolDatum}
use utils.{mock_transaction}

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
  // Reference data
  otc_nft_policy_id_tx_out_ref: OutputReference,
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
    // Reference data
    otc_nft_policy_id_tx_out_ref: OutputReference {
      transaction_id: #"0000000000000000000000000000000000000000000000000000000000000000",
      output_index: 0,
    },
    // Values
    min_ada: 2000000,
    mayz_deposit: 100,
    token_amount: 1000000,
    mayz_locked: 100,
  }
}

fn mock_nft_params(assets: TestAssets) -> OTCNFTParams {
  OTCNFTParams {
    pp_otc_nft_policy_id_tx_out_ref: assets.otc_nft_policy_id_tx_out_ref,
    pp_otc_validator_hash: assets.otc_validator_hash,
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

test mint_nft() {
  let assets = test_assets()
  let params = mock_nft_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(params.pp_otc_validator_hash)
  let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)
  // Create reference input that must be consumed
  let ref_input =
    Input {
      output_reference: params.pp_otc_nft_policy_id_tx_out_ref,
      output: Output {
        address: mock_creator_address(assets),
        value: from_asset(#"", #"", 2000000),
        datum: NoDatum,
        reference_script: None,
      },
    }

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

  // Create OTC output 
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

  // Mint value with both tokens
  let mint_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, 1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1),
    )

  let transaction =
    mock_transaction(
      [protocol_ref],
      [ref_input],
      [otc_output],
      mint_value,
      [datum.od_creator],
    )

  validate_mintNFT(params, otc_nft_policy_id, transaction) == True
}

test burn_nft() {
  let assets = test_assets()
  let params = mock_nft_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(params.pp_otc_validator_hash)
  let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO containing both tokens and datum
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

  // Create output returning assets to creator
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

  // Burn value for both tokens
  let burn_value =
    merge(
      from_asset(otc_policy_id, params.pp_otc_id_tn, -1),
      from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, -1),
    )

  let transaction =
    mock_transaction(
      [protocol_ref],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  validate_burnNFT(params, otc_nft_policy_id, transaction) == True
}

test invalid_mint() {
  let assets = test_assets()
  let params = mock_nft_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(params.pp_otc_validator_hash)
  let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create reference input that must be consumed
  let ref_input =
    Input {
      output_reference: params.pp_otc_nft_policy_id_tx_out_ref,
      output: Output {
        address: mock_creator_address(assets),
        value: from_asset(#"", #"", 2000000),
        datum: NoDatum,
        reference_script: None,
      },
    }

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

  // Create OTC output but missing protocol reference and MAYZ deposit
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

  // Try to mint only NFT token without OTC ID token
  let mint_value = from_asset(otc_nft_policy_id, datum.od_otc_nft_tn, 1)

  let transaction =
    mock_transaction(
      [protocol_ref],
      [ref_input],
      [otc_output],
      mint_value,
      [datum.od_creator],
    )

  // Should fail because:
  // Missing OTC ID token mint
  validate_mintNFT(params, otc_nft_policy_id, transaction) == False
}

test invalid_burn() {
  let assets = test_assets()
  let params = mock_nft_params(assets)
  let otc_policy_id = assets.otc_validator_hash
  let otc_nft_policy_id = assets.otc_nft_policy_id
  let otc_validator_address = from_script(params.pp_otc_validator_hash)
  let protocol_validator_address = from_script(params.pp_protocol_policy_id)
  let protocol_datum = mock_protocol_datum(assets)
  let datum = mock_otc_datum(assets)

  // Create input OTC UTXO containing both tokens and datum
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

  // Create output returning assets to creator
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

  // Burn value for both tokens
  let burn_value = from_asset(otc_policy_id, params.pp_otc_id_tn, -1)

  let transaction =
    mock_transaction(
      [protocol_ref],
      [otc_input],
      [creator_output],
      burn_value,
      [datum.od_creator],
    )

  // Should fail because:
  // Not burning OTC ID token
  validate_burnNFT(params, otc_nft_policy_id, transaction) == False
}
