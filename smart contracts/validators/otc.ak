// Mint

use aiken/collection/list
use cardano/transaction.{
  ScriptPurpose, Output, OutputReference, Transaction, find_script_outputs,
}
use cardano/address.{Credential}
use cardano/assets.{Value, AssetName, tokens}
use aiken/transaction/value.{from_minted_value}

type MintingParams2 {
  tn: AssetName,
  output_ref: OutputReference,
}

type Action {
  Minting
  Burning
}

validator otc_mint (m2: MintingParams2) {
    mint(redeemer: Action, policy_id: PolicyId, ctx: Transaction) {
    let ScriptContext { transaction: Transaction { mint, inputs, .. }, purpose } =
      ctx

    when purpose is {
      Mint(this_script_policy_id) -> {
        expect [Pair(token_name, amount)] =
          mint
            |> from_minted_value()
            |> tokens(this_script_policy_id)
            |> to_pairs()

        when r is {
          Minting -> {
            let is_input_consumed =
              list.any(
                inputs,
                fn(input) { input.output_reference == m2.output_ref },
              )
            is_input_consumed && amount == 1 && token_name == m2.tn
          }
          Burning -> amount == -1 && token_name == m2.tn
        }
      }
      _ -> False
    }
  }
}