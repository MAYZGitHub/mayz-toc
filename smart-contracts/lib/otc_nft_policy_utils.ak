use aiken/collection/list
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{Input, Transaction}
use types.{OTCDatum, OTCNFTParams}
use utils.{
  get_otc_from_inputs, get_otc_from_outputs, get_protocol_from_inputs_ref,
  validate_otc_name,
}

/// Validates minting of new OTC NFT token. Runs along CreateOTC redeemer
pub fn validate_mintNFT(
  params: OTCNFTParams,
  otc_nft_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  let otc_policy_id = params.pp_otc_validator_hash

  // Verify that referenced UTXO is consumed (ensures policy uniqueness)
  expect Some(_reference_input) =
    list.find(
      transaction.inputs,
      fn(input) {
        input.output_reference == params.pp_otc_nft_policy_id_tx_out_ref
      },
    )

  // Get protocol datum from reference input for parameter validation
  expect Some((_, protocolDatum_Ref)) =
    get_protocol_from_inputs_ref(
      transaction,
      params.pp_protocol_policy_id,
      params.pp_protocol_id_tn,
      1,
    )

  // Get the OTC output being created to validate OTC NFT token name and fields od_otc_nft_policy_id and od_otc_nft_tn
  expect Some((_, otcDatum_Out)) =
    get_otc_from_outputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  let otcDatum_Out_Control =
    OTCDatum {
      ..otcDatum_Out,
      od_otc_nft_policy_id: otc_nft_policy_id,
      od_mayz_policy_id: protocolDatum_Ref.pd_mayz_policy_id,
      od_mayz_tn: protocolDatum_Ref.pd_mayz_tn,
      od_mayz_locked: protocolDatum_Ref.pd_mayz_deposit_requirement,
    }

  and {
    // Both OTC ID and NFT must be minted
    // Ensures that the OTC Contract runs alongside the OTC NFT Policy because the OTC ID token is minted
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == 1,
    quantity_of(transaction.mint, otc_nft_policy_id, otcDatum_Out.od_otc_nft_tn) == 1,
    // Verify OTC NFT name format
    validate_otc_name(
      otcDatum_Out.od_otc_nft_tn,
      otcDatum_Out.od_token_tn,
      otcDatum_Out.od_token_amount,
    ),
    // Minimum ADA validation
    otcDatum_Out.od_token_amount > 0,
    // Minimum ADA validation
    otcDatum_Out.od_min_ada > 0,
    // Datum validations
    otcDatum_Out == otcDatum_Out_Control,
  }
}

/// Validates burning of OTC NFT and OTC ID tokens
pub fn validate_burnNFT(
  params: OTCNFTParams,
  otc_nft_policy_id: PolicyId,
  transaction: Transaction,
) -> Bool {
  let otc_policy_id = params.pp_otc_validator_hash
  // Get input OTC data to verify correct tokens are being burned
  expect Some((_, otcDatum_In)) =
    get_otc_from_inputs(transaction, otc_policy_id, params.pp_otc_id_tn, 1)

  and {
    // Both OTC ID and NFT must be burned
    quantity_of(transaction.mint, otc_policy_id, params.pp_otc_id_tn) == -1,
    quantity_of(transaction.mint, otc_nft_policy_id, otcDatum_In.od_otc_nft_tn) == -1,
  }
}
