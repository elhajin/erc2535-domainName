//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract hash is Test {
    function test_hashing() public {
        string memory toHash = "test.messge.to.hash";
        //hash the string :
        //@note : the keccak256 function don't accept the refernce of string
        bytes32 hashStr = keccak256("test.messge.to.hash");
        bytes memory referenceStrToByt = abi.encodePacked(toHash);
        bytes memory strToByt = abi.encodePacked("test.messge.to.hash");

        bytes32 hashReferByt = keccak256(referenceStrToByt);
        bytes32 hashByt = keccak256(strToByt);

        console.logBytes(referenceStrToByt);
        console.logBytes(strToByt);

        console.log(" hashes : ");
        console.logBytes32(hashReferByt);
        console.logBytes32(hashByt);

        console.logBytes32(hashStr);
        assertEq(hashByt, hashReferByt);
        assertEq(hashReferByt, hashStr);
    }
}
