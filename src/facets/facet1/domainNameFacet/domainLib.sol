//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./structs.sol";
error MoreThan32Bytes(uint256 length);
error DomainNotAvailable(address owner);
error DomainNameOutOfLength(uint256 length);
error NoAuctionAvailable();
error OutOfTime();
library domainLib {
    string public constant TOP_LEVEL_DOMAIN = ".mnt";
    uint128 public constant LIFE_TIME_DOMAIN = 0.1 ether;
    uint public constant LIFE_TIME_OWNERSHIP = ~uint256(0);
    uint public constant YEAR = 365 days;

    function _getDiscount(uint128 _price, uint8 _years) internal pure returns (uint128 price) {
        // get the percentage of _years * 7  from the price
        if (_years <= 10) {
            uint256 percentage = (_years) * 7 * price / 100;
            price = uint128(_price + (_price - percentage) * _years);
        } else {
            price = LIFE_TIME_DOMAIN;
        }
    }

    function _getDomainPrice(string memory _domain) internal pure returns (uint128 price) {
        if (bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length > 32) {
            revert DomainNameOutOfLength(bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length);
        }
        if (bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length >= 20) {
            price = 0.009 ether;
        }
        if (
            bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length >= 10
                && bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length < 20
        ) {
            price = 0.001 ether;
        } else if (bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length < 10) {
            price = 0.0005 ether;
        }
    }

    function _checkDomain(mapping(string => domainInfo) storage self, string memory _domain) internal view {
        if (bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length > 32) {
            revert DomainNameOutOfLength(bytes(_domain).length);
        }
        if (self[_domain].owner != address(0)) revert DomainNotAvailable(self[_domain].owner);
    }

    function _setDomain(mapping(string => domainInfo) storage self,string memory _domain, address _owner,uint8 _years,uint id) internal {
       uint year = _years > 10 ? LIFE_TIME_OWNERSHIP : (_years * YEAR);
       self[_domain] = domainInfo(_owner,block.timestamp,year ,id);
    }
    function _updateOwner (mapping(string => domainInfo) storage self,string memory _domain, address _newOwner)internal{
        self[_domain].owner = _newOwner;
    }

    
    
}
