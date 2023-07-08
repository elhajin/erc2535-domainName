//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract self {
    address public immutable _self = address(this);
}
