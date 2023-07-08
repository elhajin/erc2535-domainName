//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {diamond} from "../../src/daimond/diamond.sol";
import {IDiamond} from "../../src/interfaces/IDiamond.sol";
import "../../src/layoutStorage.sol";

contract DiamondTest is Test {
    // work flow :
    /*
    1-> deploy the contract : set the owner as a variable then deploy with it 
    2-> cutFacet test : test to cut facet with all failed and non condition 
    3-> test add() : test the add() function 
    4-> test remove(): function 
    5-> 
    */

    address owner = 0x3806d55C85c67115366bffd3324eC5d76b0Cd56a;
    IDiamond diam;
    address facet1 = address(new testFacet());

    function setUp() public {
        vm.startPrank(owner);
        diamond Contract = new diamond();
        diam = IDiamond(address(Contract));
        vm.stopPrank();
    }

    // function to test cutfacet contract :
    function test__cutFacet() public {
        string[] memory funcNames;
        funcNames[0] = "add(uint256,uint256)";
        funcNames[1] = "getAddress()";
        facetCut memory validFacetCut = facetCut(facet1, _getSelectors(funcNames));
        // call the cutFacet with non owner

        // call cutFacet with an Eoa address;
        // call the cut facet with no selectors
        // call the cut facet with address zero
    }

    function _getSelectors(string[] memory names) internal pure returns (bytes4[] memory selectors) {
        // bytes4[] memory selector;
        for (uint256 i; i < names.length; i++) {
            selectors[i] = (bytes4(abi.encodeWithSignature(names[i])));
        }
    }

    function _getStructsFacetCut()
        internal
        view
        returns (
            facetCut memory valid,
            facetCut memory noSelectors,
            facetCut memory facetEoa,
            facetCut memory facetDiamon,
            facetCut memory facetAddressZero
        )
    {
        string[] memory funcNames;
        funcNames[0] = "add(uint256,uint256)";
        funcNames[1] = "getAddress()";
        valid = facetCut(facet1, _getSelectors(funcNames));
        bytes4[] memory empty;
        noSelectors = facetCut(facet1, empty);
        facetEoa = facetCut(address(32424223), _getSelectors(funcNames));
        facetDiamon = facetCut(address(diam), _getSelectors(funcNames));
        facetAddressZero = facetCut(address(0), _getSelectors(funcNames));
    }
}

contract testFacet {
    address immutable addr = address(this);

    function add(uint256 x, uint256 y) public pure returns (uint256) {
        return x + y;
    }

    function getAddress() public view returns (address) {
        return addr;
    }
}
