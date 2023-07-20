//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {self} from "./self.sol";

error Delegatecall_NoDelegateCall();
error Delegatecall_OnlyDelegateCall();

abstract contract delegateCall is self {
    modifier noDelegatecall() {
        if (address(this) != _self) revert Delegatecall_NoDelegateCall();
        _;
    }

    modifier onlyDelegatecall() {
        if (address(this) == _self) revert Delegatecall_OnlyDelegateCall();
        _;
    }
}
