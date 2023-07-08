//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract arrayStorage is Test {
    address owner = address(0);
    uint256[] simpleArray;
    string[] strArray;
    uint256[][] nestedArray;

    function test_simpleArray() public {
        simpleArray.push(10);
        simpleArray.push();
        simpleArray.push(2);
        simpleArray.push(14);
        console.log("the first", simpleArray[1]);
        // check array length in the slot 0 :
        uint256 len = uint256(_readStorageSlot(28));
        assertEq(len, 4);
        console.log("==> array length: ", len);
        // get the slot where the actual array stored
        uint256 simpleArrayLocation = _hash(28);
        // read array by index:
        assertEq(_bytesToUint(_readStorageSlot(simpleArrayLocation)), 10);
        assertEq(_bytesToUint(_readStorageSlot(simpleArrayLocation + 3)), 14);
    }

    function test_array() public {
        nestedArray.push(); // create array 0
        nestedArray.push(); // create array 1
        nestedArray[0].push(1);
        nestedArray[1].push(11);
        nestedArray[0].push(2);
        // get the slot of the array 0 :
        assertEq(uint256(_readStorageSlot(30)), 2);
        // get the loction of array 0 and 1 :
        uint256 slotarray0 = _hash(30);
        uint256 slotarray1 = slotarray0 + 1;
        // get the actual location of array 0,1 :
        uint256 locationArray0 = _hash(slotarray0);
        uint256 locationArray1 = _hash(slotarray1);
        // check the stored values :
        assertEq(uint256(_readStorageSlot(locationArray0)), 1);
        assertEq(uint256(_readStorageSlot(locationArray0 + 1)), 2);
        assertEq(uint256(_readStorageSlot(locationArray1)), 11);
        assertEq(uint256(_readStorageSlot(locationArray1 + 2)), 0);
    }

    function _readStorageSlot(uint256 slot) internal view returns (bytes32 value) {
        value = vm.load(address(this), bytes32(slot));
    }

    function _hash(uint256 slot) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(slot)));
    }

    function _bytesToUint(bytes32 f) internal pure returns (uint256 v) {
        v = uint256(f);
    }
}

contract toTest {
    address owner = address(0);
    uint256[] simpleArray;
    string[] strArray;
    uint256[][] nestedArray;
}
