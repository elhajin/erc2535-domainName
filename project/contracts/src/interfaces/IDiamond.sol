//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct facetCut {
    address facet;
    bytes4[] selectors;
}

interface IDiamond {
    function cutFacet(facetCut calldata facetCut) external;

    function remove(bytes4[] calldata selectors) external;

    function add(facetCut calldata _facetCut) external;
}
