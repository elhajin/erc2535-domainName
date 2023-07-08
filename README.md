# Daimond Proxy Pattern:

### in this repo we gonna walk through the **EIP2535** that stands for a Daimonds implementation of an upgradable contract :

## **_<span style = "color: #90EE90"> What is a Daimonds Proxy ? </span>_**

_[EIP-2535](https://eips.ethereum.org/EIPS/eip-2535), also known as "Diamond Standard," is an Ethereum Improvement Proposal that introduces a modular and upgradeable architecture for smart contracts on the Ethereum blockchain. Proposed by Nick Mudge, it aims to provide developers with a standardized way of building complex and upgradable smart contracts._

The main goal of EIP-2535 is to address the challenges of code reuse and contract upgradability in Ethereum. Traditionally, building complex contracts with upgradability required intricate and error-prone coding practices. The Diamond Standard proposes a design pattern that simplifies contract development, enhances code reuse, and enables contract upgrades without sacrificing security.

The key concepts and features of the Diamond Standard are as follows:

- Diamonds: A Diamond is a contract that acts as a proxy or a hub for multiple facets. Each facet represents a separate module or functionality of the contract. Diamonds allow for the aggregation of different functionalities from various facets into a single contract.

- Facets: Facets are individual modules that encapsulate specific functionality or logic. They can be added, modified, or removed from a Diamond contract without affecting the other facets or the main contract itself.

- Function Selectors: [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535) introduces a standard way of handling function calls and selectors across different facets. By using function selectors, developers can easily add, remove, or replace functions in different facets without causing conflicts or breaking the contract's overall functionality.

- Call Routing: The Diamond contract acts as a dispatcher, routing function calls to the appropriate facet based on the function selector. This allows for selective modification or upgrade of specific functionalities while keeping the rest of the contract intact.

- Storage Layout: [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535) defines a standardized way of managing contract storage across different facets. It ensures that each facet has its own designated storage slots, avoiding conflicts and providing efficient storage management.

### **_in this repo we gonna walk through by writing a daimond contract and some facets to it and test it with foundry_**

## **_<span style = "color: #90EE90"> Repo Structure: </span>_**

## **traces**:
