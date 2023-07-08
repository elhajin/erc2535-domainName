//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract helperFunctions {
    /**
     * @dev get a signature for one function
     * @param nameAndParams the name of the function and the paramters type that it takes in order
     *  EXAMPLE: function foo(address fofo, uint ffoo,string memory ts);
     *  - to get the signature of this function you have to call : getSignature("foo(address,uint,string)")
     */
    function getSignature(string memory nameAndParams) public pure returns (bytes4 sig) {
        sig = bytes4(abi.encodeWithSignature(nameAndParams));
    }
}
