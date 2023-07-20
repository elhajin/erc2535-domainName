//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {abstractDiamond} from "./abstractDiamond.sol";

contract diamond is abstractDiamond {
    /**
     * @dev the fallback function get excute if the called funtion not exist in diamond contract :
     *
     */
    fallback() external payable {
        // check that the contract have
        address facet = _fallbackCheck();
        assembly {
            //copy the data to the memory
            calldatacopy(0, 0, calldatasize())
            // delegate call with the data from memory to the facet address
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // return the data from the call:
            returndatacopy(0, 0, returndatasize())
            // return the data from the call (reverted or not);
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
