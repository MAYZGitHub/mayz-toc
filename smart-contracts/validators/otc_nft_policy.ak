use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use otc_nft_policy_utils.{validate_burnNFT, validate_mintNFT}
use types.{BurnNFT, MintNFT, NFTRedeemer, OTCNFTParams}

/// OTC NFT minting policy validator
/// Controls minting and burning of OTC NFT tokens
validator otc_nft_policy(params: OTCNFTParams) {
  mint(
    redeemer: NFTRedeemer,
    otc_nft_policy_id: PolicyId,
    transaction: Transaction,
  ) {
    when redeemer is {
      MintNFT -> validate_mintNFT(params, otc_nft_policy_id, transaction)
      BurnNFT -> validate_burnNFT(params, otc_nft_policy_id, transaction)
    }
  }

  else(_) {
    fail
  }
}
