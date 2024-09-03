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
  - [Design and Architecture](#design-and-architecture)
  - [Use Cases and Benefits](#use-cases-and-benefits)
  - [Project Plan](#project-plan)
  - [Milestones](#milestones)
  - [Links](#links)
  - [About MAYZ Protocol](#about-mayz-protocol)
  - [Acknowledgements](#acknowledgements)

## Why This OTC?
Liquidity issues on Cardano's DEXs can lead to high slippage, discouraging large trades. As detailed in the [Research report on liquidity challenges in the Cardano ecosystem](https://docs.google.com/document/d/1WZ7hvn7w34FM8f7xvnZdzBhkokn43SrJW2hU8AAui-c/), the absence of sufficient liquidity for large transactions often results in price impacts that deter large investors. By leveraging a smart contract-based OTC solution, MAYZ provides an alternative that reduces slippage and increases market efficiency, making Cardano a more attractive option for high-volume traders.

## Documentation

**Gitbook**

https://mayz-1.gitbook.io/mayz-otc

## Design and Architecture
**Concept**:  
Implementing an OTC market using Cardano's smart contract capabilities to create a trustless environment for large transactions.

**Architecture Overview**:  
- Smart Contracts: Responsible for locking fungible tokens and minting NFTs representing the locked value.
- Trading Mechanism: NFTs can be traded in secondary marketplaces, allowing users to sell large volumes without slippage.
- Data Management: Using smart contract datums to track and manage locked tokens and associated NFTs.

**OTC on Cardano - How It Works**:  
A Haskell smart contract on the Cardano blockchain allows a certain amount of fungible tokens to be locked. The smart contract releases an NFT corresponding to the locked tokens. The contract securely stores the tokens and maintains a datum that records details of the minted NFT and associated tokens. This setup supports issuing an NFT in exchange for tokens and allows reversing the transaction to retrieve the locked tokens.

## Use Cases and Benefits
- **Institutional Investors**: Facilitates large-scale transactions without impacting market prices, offering a more predictable trading environment.
- **New Projects**: Provides a way to raise funds and manage liquidity without the high costs and risks associated with traditional liquidity provision methods.
- **High-Volume Traders**: Reduces slippage and trading costs, making Cardano more competitive for large-scale operations.
- **NFT Enthusiasts**: By combining fungible and non-fungible tokens, the solution encourages innovation and broader participation within the ecosystem.

## Project Plan
The project will proceed in phases, starting with research and planning, followed by development, testing, and public release. The project plan outlines the objectives, timeline, and deliverables, ensuring a structured approach to developing the Trustless OTC solution. Key phases include:

1. Research and analysis of liquidity issues.
2. Creation of a detailed project plan and timeline.
3. Development of functional and technical documentation.
4. Prototype development, testing, and public release.

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

## Links

- Tackling Slippage on Cardano: MAYZ Trustless OTC Smart Contract - Catalyst Proposal: [Proposal](https://cardano.ideascale.com/c/idea/120544) 
- Milestones status: [Milestones](https://milestones.projectcatalyst.io/projects/1200222) 
- MAYZ's OTC GitHub repository: [Repository](https://github.com/MAYZGitHub/mayz-otc) 
- MAYZ's OTC Documentarion: [GitBook](https://mayz-1.gitbook.io/mayz-otc) 
- [MAYZ Website](https://mayz.io/)
- [MAYZ GitHub](https://github.com/MAYZGitHub/)

## About MAYZ Protocol
MAYZ Protocol is a development team from Latin America, building on Cardano for the last three years. We run [MAYZ](https://adapools.org/pool/pool1r8lmsrdure385hz647kl2qjhyyxkdle4au5krjcsqed4x8227k3) Stake Pool and are dedicated to creating open-source projects that foster transparency, collaboration, and community involvement in developing decentralized finance solutions.

Our flagship project, MAYZ Protocol, is a decentralized protocol that allows the creation and management of decentralized and trustless investment funds. The Index Funds smart contract has been open-sourced and reviewed by TxPipe. The protocol is currently live on Testnet, with plans for an audit and Mainnet launch later this year.

By adopting an open-source approach, MAYZ encourages innovation, improves security, and promotes the widespread adoption of its permissionless platform for creating and managing investment funds on the Cardano blockchain. This approach aligns with the decentralized and community-driven nature of blockchain technology, ensuring MAYZ remains accessible and adaptable to the evolving needs of the Cardano ecosystem.

## Acknowledgements
This project is part of a funded proposal from the Cardano IdeaScale - Project Catalyst - Fund 12. We would like to thank the Cardano community and the Catalyst team for their support and collaboration in making this project a reality. For more information on Project Catalyst, visit [Cardano IdeaScale](https://cardano.ideascale.com/).
