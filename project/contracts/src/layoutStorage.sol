//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
////  this file will contain all the storage structs types for facets and diamond contracts ;
/**
 * @notice this type of struct used to cutFacet by providing the facet to cut and the function selectors
 *          Associated with it;
 */

struct facetCut {
    address facet;
    bytes4[] selectors;
}

/**
 * @notice struct that store the functions selectors of a facet and the position of facet in "facets" array;
 */
struct selectorsAndPosition {
    bytes4[] selectors;
    uint32 position;
}
/**
 * @notice struct that store the facet for a selector , and the selector position in the array "selectors"
 */

struct facetAndPostion {
    address facet;
    uint32 postion;
}

/**
 * @param facetToSelectors map the address of a facet to his functions selectors that can be called from the diamond
 *        contract , and it's position in the "facets" array
 * @param selectorToFacet map a function selector to his facet and his position in the array selectors;
 * @param facets array that store all facets that the daimond could call one or more of it's functions , via delegate call
 * @param ownership the contract or EOA account that's consider the owner of the daimond contract
 *
 */
struct mainStorage {
    mapping(address facet => selectorsAndPosition) facetToSelectors;
    mapping(bytes4 selector => facetAndPostion) selectorToFacet;
    address[] facets;
    address ownership;
    uint8 initialized;
}

/**
 * @dev this is the storage sturct that the diamond functions (beside immutable functions) can reach (read and write)
 * @notice we did reserve some slots for
 */
struct appStorage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address spender => mapping(address owner => uint256 amoundtToSpen)) allowance;
    mapping(address owner => uint256 balance) balances;
}
