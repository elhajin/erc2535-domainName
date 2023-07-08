//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../library/diamondLib.sol";
import "../helperFunctions/delegatecall.sol";

abstract contract abstractDiamond is self, delegateCall {
    /**
     * @dev this abstract contract will contain all the immutable functions in the diamond contract;
     * @dev the main Diamond contract should inherit from this contract ;
     */

    constructor() {
        diamondLib._init();
    }

    function cutFacet(facetCut calldata _facetCut) external noDelegatecall {
        diamondLib.cutFacet(_facetCut);
    }

    function remove(bytes4[] calldata selectors) external noDelegatecall {
        diamondLib.remove(selectors);
    }

    function add(facetCut calldata _facetCut) external noDelegatecall {
        diamondLib.add(_facetCut);
    }

    function _fallbackCheck() internal view returns (address) {
        return diamondLib._fallbackCheck();
    }
}
