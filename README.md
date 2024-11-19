# MAYZ Trustless OTC Smart Contract
Tackling Slippage on Cardano

## Overview
MAYZ Trustless OTC Smart Contract aims to solve liquidity and slippage issues for large transactions on Cardano by implementing a decentralized, non-custodial OTC (Over-The-Counter) solution. This will allow users to execute high-volume trades without directly relying on DEX liquidity, reducing slippage and providing a more efficient trading experience.

## Table of Contents
- [MAYZ Trustless OTC Smart Contract](#mayz-trustless-otc-smart-contract)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Why This OTC?](#why-this-otc)
  - [Documentation](#documentation)
  - [Analysis of Possible Solutions](#analysis-of-possible-solutions)
    - [Individualized Solution:](#individualized-solution)
    - [Institutional Solution:](#institutional-solution)
    - [Chosen Solution: Individualized Approach](#chosen-solution-individualized-approach)
    - [Role of MAYZ and MAYZ Token:](#role-of-mayz-and-mayz-token)
    - [Considerations:](#considerations)
    - [Special Considerations:](#special-considerations)
  - [Design and Architecture](#design-and-architecture)
  - [Smart Contracts](#smart-contracts)
  - [Transition Plan: Individual to Institutional Approach](#transition-plan-individual-to-institutional-approach)
  - [External Interactions](#external-interactions)
  - [Use Cases and Benefits](#use-cases-and-benefits)
  - [Project Plan and Status](#project-plan-and-status)
  - [Milestones](#milestones)
  - [Cardano Catalyst Reports](#cardano-catalyst-reports)
  - [Links](#links)
  - [About MAYZ Protocol](#about-mayz-protocol)
  - [Acknowledgements](#acknowledgements)

## Why This OTC?
Liquidity issues on Cardano's DEXs can lead to high slippage, discouraging large trades. As detailed in our [Research report on liquidity challenges in the Cardano ecosystem](https://docs.google.com/document/d/1WZ7hvn7w34FM8f7xvnZdzBhkokn43SrJW2hU8AAui-c/), the absence of sufficient liquidity for large transactions often results in price impacts that deter large investors. By leveraging a smart contract-based OTC solution, MAYZ's OTC provides an alternative that reduces slippage and increases market efficiency, making Cardano a more attractive option for high-volume traders.

## Documentation
- [Gitbook](https://mayz-1.gitbook.io/mayz-otc)

## Analysis of Possible Solutions

### Individualized Solution:
- **Functionality**: Allows individual users to exchange large amounts of tokens for NFTs representing those tokens, which can then be traded in secondary markets.
- **Pros**: Flexibility and ease of use for individual users.
- **Cons**: Lack of clarity on what each NFT represents, which can be mitigated by using detailed metadata and descriptive token names.
- **Architecture**: Managed with a single minting policy and a smart contract or a single Plutus 3 script for both minting and validation. Tokens are stored in a specific address managed by the smart contract. The datum holds crucial information including details about the creator (for MAYZ token retrieval), the quantity and specifics of the tokens represented by the NFT, and other transaction-related data.

### Institutional Solution:
- **Functionality**: Protocols can create their own OTC contracts to manage large amounts of their own tokens, with the ability to define specific rules for issuing NFTs representing fixed amounts of tokens.
- **Pros**: Greater organization and control over exchanges, with clear and uniform rules.
- **Cons**: Need for identification and control over who can operate, and establishing consistent standards which may require reliable oracles for precise token issuance information.
- **Architecture**: Each protocol may have its own contract and minting policy (each with its own address for storing tokens and minting OTC tokens) or a single Plutus 3 script managing both minting and validation. The datum in institutional contracts includes parameters set by the protocol, such as token amounts and standards. If a centralized protocol is needed for multiple projects, a main protocol smart contract could maintain shared parameters in its datum.

### Chosen Solution: Individualized Approach
After careful consideration, the Individualized Solution has been chosen for the initial phase of the MAYZ Trustless OTC Smart Contract project. This solution provides the necessary flexibility and ease of use to meet the current needs of individual users while effectively addressing the liquidity and slippage issues in Cardano's ecosystem. 

The roadmap for this solution includes:
1. Implementing the basic functionality to allow users to exchange tokens for NFTs using a single smart contract and minting policy.
2. Ensuring clear metadata and naming conventions for NFTs to enhance transparency.
3. Gathering user feedback and analyzing the market response to refine and expand the solution.
4. Exploring the potential to integrate institutional-level solutions as the project evolves, based on market demand and technological advancements.

**Note about Cardano Catalyst**: This initial approach meets our project's current goals, as funded by Cardano Project Catalyst, while laying the foundation for future growth and adaptation as we better understand market needs and user interaction with our services.

### Role of MAYZ and MAYZ Token:
- **MAYZ's Role**: In an institutional setup, MAYZ would decide who can create OTC contracts and set rules for NFT issuance.
- **MAYZ Token Utility**: Required for both individual and institutional cases. Individuals need MAYZ tokens to initiate contracts and mint NFTs, and protocols would use MAYZ tokens alongside their tokens to create and manage OTC contracts. MAYZ tokens can be retrieved once no tokens are left in the contract.

### Considerations:
- **Standardization vs. Flexibility**: For institutional cases, protocols could either set their own rules for token issuance or adopt standard ones set by MAYZ, such as a fixed percentage of total tokens (0.1%, 1%). This could be challenging without accurate on-chain data, often needing oracles.
- **Naming Conventions**: Tokens could follow a standard like "black", "silver", "gold" to represent different amounts, or each protocol could define their own. For individuals, NFT names would illustrate what they represent, e.g., "OTC-LEND-1.50M" for 1,500,000 LEND tokens.

### Special Considerations:
- **Multi-Token Representation**: Exploring scenarios where OTC tokens could represent more than one type of token, e.g., 1.5M LEND and 2M MIN, offering flexible asset bundling.

## Design and Architecture
This section describes the design and architecture of the chosen Individualized Solution.

**Concept**:
Implementing an OTC market using Cardano's smart contract capabilities to create a trustless environment for large transactions, focused on individual users.

**OTC Token Flow**:  
1. **Token Locking**: Users deposit tokens into the smart contract.
2. **NFT Issuance**: The contract mints an NFT that acts as a key to the deposited tokens.
3. **Trading**: The NFT can be traded on secondary markets, representing ownership of the underlying tokens.
4. **Redemption**: The holder of the NFT can return it to the contract to unlock the tokens.

**Datum Details**:
The datum plays a crucial role in the OTC process, storing essential information:
- Creator details: Enables the retrieval of MAYZ tokens upon completion of the exchange (when someone has traded the NFT for the backed tokens).
- Token representation: Specifies the quantity of tokens represented by the NFT.
- Token specifics: Includes details about the policy ID and token name of the backed tokens.
- Transaction data: Stores other relevant transaction-related information.

## Smart Contracts

[README](./smart-contracts/README.md)

## Transition Plan: Individual to Institutional Approach
This is our vision for potential future expansion:

1. Coexistence: Individual and institutional approaches may coexist, catering to different user needs.
2. Separate Deployment: Institutional contracts will be deployed separately, not replacing individual contracts.
3. Continuity: Existing individual OTC tokens will remain valid and functional.
4. Unified Interface: We plan to develop a single entry point listing both individual and institutional OTC options.
5. Incentivization: Based on market dynamics, we may introduce incentives to encourage the use of institutional OTCs if deemed beneficial.

This flexible approach allows us to adapt to market needs while ensuring continuity for early adopters.

## External Interactions
While the OTC smart contracts don't directly depend on oracles or external systems, their utility is realized through interaction with:
- **NFT Marketplaces:** For trading OTC tokens.
- **Exchange Platforms:** For utilizing OTC tokens in various trading scenarios.

These interactions are facilitated by the standard Cardano token protocols, ensuring broad compatibility.

## Use Cases and Benefits
- **Institutional Investors**: Facilitates large-scale transactions without impacting market prices, offering a more predictable trading environment.
- **New Projects**: Provides a way to raise funds and manage liquidity without the high costs and risks associated with traditional liquidity provision methods.
- **High-Volume Traders**: Reduces slippage and trading costs, making Cardano more competitive for large-scale operations.
- **NFT Enthusiasts**: By combining fungible and non-fungible tokens, the solution encourages innovation and broader participation within the ecosystem.

## Project Plan and Status
The project will proceed in phases, starting with research and planning, followed by development, testing, and public release. The project plan outlines the objectives, timeline, and deliverables, ensuring a structured approach to developing the Trustless OTC solution. Key phases include:

1. Research and analysis of liquidity issues (Completed in Milestone 1)
2. Creation of a detailed project plan and timeline (Completed in Milestone 1)
3. Development of functional and technical documentation (Initiated in Milestone 1, Ccompleted in Milestone 2)
4. Prototype development, testing, and public release

## Milestones
1. **Project Planning, Research, and Technical Documentation**  
   - Outputs: Detailed project plan, liquidity research report, and initial functional documentation.
   - Acceptance Criteria: All documents are clear, publicly accessible, and published on MAYZ's OTC GitHub repository.

2. **Smart Contract Prototype Architecture**  
   - Outputs: Detailed architecture diagram and initial source code.
   - Acceptance Criteria: Public access to detailed documents and MAYZ's OTC GitHub repository.

3. **Smart Contract Prototype Development**  
   - Outputs: Complete smart contract source code with all validations.
   - Acceptance Criteria: Test suite developed with positive test results, source code publicly accessible on MAYZ's OTC GitHub repository.

4. **Open-Source Release and Community Engagement**  
   - Outputs: Deployment of smart contracts on Mainnet, basic website for interactions, and educational resources.
   - Acceptance Criteria: Contracts deployed, website functional, educational content available, and all resources meet Catalyst requirements.

## Cardano Catalyst Reports
Here are the links to the Catalyst Milestone reports for the project. Each report provides an update on the project's progress, achievements, and next steps for each milestone.

[Milestone 1 Report](./catalyst-reports/MILESTONE-01.md)

[Milestone 2 Report](./catalyst-reports/MILESTONE-02.md)

## Links
- Tackling Slippage on Cardano: MAYZ Trustless OTC Smart Contract - Catalyst Proposal: [Proposal](https://cardano.ideascale.com/c/idea/120544) 
- Catalyst Milestones status page: [Milestones](https://milestones.projectcatalyst.io/projects/1200222) 
- MAYZ's OTC GitHub repository: [Repository](https://github.com/MAYZGitHub/mayz-otc) 
- MAYZ's OTC Documentation: [GitBook](https://mayz-1.gitbook.io/mayz-otc)
- [MAYZ Website](https://mayz.io/)
- [MAYZ X](https://twitter.com/MAYZProtocol)
- [MAYZ Discord](https://discord.com/invite/6xkbynuNrj)
- [MAYZ Medium](https://medium.com/@MAYZprotocol)
- [MAYZ GitHub](https://github.com/MAYZGitHub/)

## About MAYZ Protocol
MAYZ Protocol is a development team from Latin America, building on Cardano for the last three years. We run [MAYZ](https://adapools.org/pool/pool1r8lmsrdure385hz647kl2qjhyyxkdle4au5krjcsqed4x8227k3) Stake Pool and are dedicated to creating open-source projects that foster transparency, collaboration, and community involvement in developing decentralized finance solutions.

Our flagship project, MAYZ Protocol, is a decentralized protocol that allows the creation and management of decentralized and trustless investment funds. The Index Funds smart contract has been open-sourced and reviewed by TxPipe. The protocol is currently live on Testnet, with plans for an audit and Mainnet launch later this year.

By adopting an open-source approach, MAYZ encourages innovation, improves security, and promotes the widespread adoption of its permissionless platform for creating and managing investment funds on the Cardano blockchain. This approach aligns with the decentralized and community-driven nature of blockchain technology, ensuring MAYZ remains accessible and adaptable to the evolving needs of the Cardano ecosystem.

## Acknowledgements
This project is part of a funded proposal from the Cardano IdeaScale - Project Catalyst - Fund 12. We would like to thank the Cardano community and the Catalyst team for their support and collaboration in making this project a reality. For more information on Project Catalyst, visit [Cardano IdeaScale](https://cardano.ideascale.com/).