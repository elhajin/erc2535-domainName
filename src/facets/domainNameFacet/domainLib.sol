//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./structs.sol";

error MoreThan32Bytes(uint256 length);
error DomainNotAvailable();
error DomainNameOutOfLength(uint256 length);
error NoAuctionAvailable();
error OutOfTime();
error NotValidPaymentAmount(uint256 price, uint256 payed);
error NotOwnerCall();
error DomainIsAlreadyForSale();
error NotValidTypeSale();

library domainLib {
    string public constant TOP_LEVEL_DOMAIN = ".mnt";
    uint128 public constant LIFE_TIME_DOMAIN = 0.1 ether;
    uint256 public constant LIFE_TIME_OWNERSHIP = ~uint256(0);
    uint256 public constant YEAR = 365 days;
    address private constant RANDOM = address(1234);
    bytes32 constant STORAGE_LOCATION = keccak256(abi.encodePacked(RANDOM, TOP_LEVEL_DOMAIN));

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

    function _setForSale(
        string calldata _domain,
        typeSale _type,
        address caller,
        uint128 price,
        uint256 period,
        uint256 startedAt
    ) internal {
        // copy to memory :
        domainInfo memory Info = _storage().domainToInfo[_domain];
        // check that the caller is the owner and domain not for sale :
        if (Info.owner != caller) revert NotOwnerCall();
        if (_storage().domainForSale[_domain].forSale) revert DomainIsAlreadyForSale();
        if (_type != typeSale.typeAuction || _type != typeSale.typeFixedPrice) revert NotValidTypeSale();
        _storage().domainForSale[_domain] = forSale(true, _type);
        // when the type sale is a fixed price type :
        if (_type == typeSale.typeFixedPrice || period == 0 || startedAt == 0) {
            _storage().fixedPrice[_domain] = fixedPriceInfo(Info.owner, price, Info.buyedAt + Info.ownerShipPeriod);
        } else if (_setAuctionTimeCheck(period, startedAt) && _type == typeSale.typeAuction) {
            // update the auction :
            _storage().auction[_domain] = auctionInfo(Info.owner, address(0), startedAt, period, price, 0);
        }
    }

    function _setAuctionTimeCheck(uint256 period, uint256 startedAt) private view returns (bool) {
        if (period > 30 days || startedAt < block.timestamp || startedAt > 30 days + block.timestamp) return false;
        else return true;
    }

    function _checkDomain(string calldata _domain) internal view {
        if (bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length > 32) {
            revert DomainNameOutOfLength(bytes(string.concat(_domain, TOP_LEVEL_DOMAIN)).length);
        }
        if (_storage().domainToInfo[_domain].owner != address(0)) revert DomainNotAvailable();
    }

    function _setDomain(
        mapping(string => domainInfo) storage self,
        string memory _domain,
        address _owner,
        uint8 _years,
        uint256 id
    ) internal {
        uint256 year = _years > 10 ? LIFE_TIME_OWNERSHIP : (_years * YEAR);
        self[_domain] = domainInfo(_owner, block.timestamp, year, id);
        _storage().ownerToDomains[_owner].push(_domain);
    }

    function _updateOwner(mapping(string => domainInfo) storage self, string memory _domain, address _newOwner)
        internal
    {
        self[_domain].owner = _newOwner;
    }

    function _storage() internal pure returns (Storage storage _mainStorage) {
        bytes32 location = STORAGE_LOCATION;
        assembly {
            _mainStorage.slot := location
        }
    }

    function _updateAuctionLive(string calldata _domain, auctionInfo memory auc, uint256 value, address currentBuyer)
        internal
    {
        // check if the value is more then lower price ,
        if (auc.currentPayed >= value || auc.lowerPrice > value) {
            revert NotValidPaymentAmount(auc.lowerPrice, value);
        } else {
            // update the last buyer and the currentPayed value;
            _storage().auction[_domain].lastBuyer = currentBuyer;
            _storage().auction[_domain].currentPayed = value;
            if (auc.lastBuyer != address(0) && auc.currentPayed > auc.lowerPrice) {
                (bool ok,) = payable(auc.lastBuyer).call{value: auc.currentPayed}("");
                require(ok, "failed to refund the last buyer");
            }
        }
        // check if the value more then current payed and ,
        // send
    }
}
