//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {appStorage} from "../../layoutStorage.sol";

// we have to create a stuct to store state variables , and reserve some position for future upgrade ;
contract haj is ERC20("haj", "hakk") {}
