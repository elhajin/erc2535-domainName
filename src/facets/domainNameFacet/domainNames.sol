//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "./domainLib.sol";

error NotValidDomainName();
error OwnerShipExpired();

error DomainExpired();
error NotStartedYet(uint256 startAt);

contract domainNames {
    using domainLib for mapping(string => domainInfo);

    /**
     * @dev this modifier is check if a domain name has expired , it will reset the owner to address(0) and make it available again
     * @param _domain the domain name to check .
     */
    modifier Expired(string calldata _domain) {
        if (
            domainLib._storage().domainToInfo[_domain].buyedAt
                + domainLib._storage().domainToInfo[_domain].ownerShipPeriod >= block.timestamp
        ) {
            domainLib._storage().domainToInfo[_domain].owner = address(0);
            domainLib._storage().domainToInfo[_domain].buyedAt = 0;
            domainLib._storage().domainToInfo[_domain].ownerShipPeriod = 0;
            // check if the domain is for sale :
            if (domainLib._storage().domainForSale[_domain].forSale) {
                _resetForSale(_domain);
            }
        }
        domainLib._checkDomain(_domain);
        _;
    }

    modifier checkAndUpdateAuction(string calldata _domain) {
        // check if this domain is in auction ;
        if (
            domainLib._storage().auction[_domain].startedAt + domainLib._storage().auction[_domain].period
                > block.timestamp
        ) {
            _updateAuctionFinal(_domain);
        }
        _;
    }

    /**
     * @dev this function is allow any user to buy a domain if it's available
     * checks:
     *  1-> check if the owner of this domain is expired , reset all only for id . and update forSale
     *  2-> check if the domain for sale in auctio and the auction is over , then update the auction info
     *  3-> check that the domain don't exist in the
     */
    function buyDomain(string calldata _domain, uint8 _years)
        external
        payable
        Expired(_domain)
        checkAndUpdateAuction(_domain)
        returns (bool success)
    {
        uint128 price;
        // when the domain not for sale :
        if (!domainLib._storage().domainForSale[_domain].forSale) {
            // get the domain price depends on how many years;
            price = domainLib._getDiscount(domainLib._getDomainPrice(_domain), _years);
            // check the msg.value is equal or more than the nedded price
            if (msg.value >= price) {
                uint256 Id = domainLib._storage().domainToInfo[_domain].id == 0
                    ? domainLib._storage().currentId
                    : domainLib._storage().domainToInfo[_domain].id;
                domainLib._storage().domainToInfo._setDomain(_domain, msg.sender, _years, Id);
            } else {
                revert NotValidPaymentAmount(price, msg.value);
            }
            // when domain for sale :
        } else if (domainLib._storage().domainForSale[_domain].forSale) {
            // when type of domain sale is fixedPrice :
            if (domainLib._storage().domainForSale[_domain].typeSale == typeSale.typeFixedPrice) {
                price = domainLib._storage().fixedPrice[_domain].price;
                if (msg.value >= price) {
                    domainLib._storage().domainToInfo._updateOwner(_domain, msg.sender);
                    address oldOwner = domainLib._storage().fixedPrice[_domain].owner;
                    domainLib._storage().fixedPrice[_domain] = fixedPriceInfo(address(0), 0, 0);
                    (bool ok,) = oldOwner.call{value: msg.value}("");
                    require(ok, "failed to send eth to the actual owner");
                } else {
                    revert NotValidPaymentAmount(price, msg.value);
                }
            }
            // when the type of domain to sale is auction:
            else if (domainLib._storage().domainForSale[_domain].typeSale == typeSale.typeAuction) {
                auctionInfo memory _auc = domainLib._storage().auction[_domain];
                if (_auc.startedAt < block.timestamp) revert NotStartedYet(_auc.startedAt);
                domainLib._updateAuctionLive(_domain, _auc, msg.value, msg.sender);
            }
        }
        return true;
    }

    /**
     * @dev function to sell the domain that you own,
     * checks:
     * 1-> the domain not already for sale , the domain not expired yet
     */
    function sellDomain(
        string calldata _domain,
        typeSale _typeSale,
        uint128 _price,
        uint256 _period,
        uint256 _startedAt
    ) external Expired(_domain) checkAndUpdateAuction(_domain) returns (bool success) {
        domainLib._setForSale(_domain, _typeSale, msg.sender, _price, _period, _startedAt);
        return true;
    }

    /**
     * receive ether ***************
     */
    receive() external payable {}

    /**
     * view functions ********************
     */
    /**
     * @dev if the domain is not owned yet it will revert
     * @param _domain domain name that end's with .mnt
     * @return an address that represent the owner of this domain
     */
    function ownerOf(string memory _domain) external view returns (address) {
        domainInfo memory _ownerOf = domainLib._storage().domainToInfo[_domain];
        if (_ownerOf.owner == address(0)) revert NotValidDomainName();
        else if (_ownerOf.ownerShipPeriod + _ownerOf.buyedAt > block.timestamp) revert OwnerShipExpired();
        return _ownerOf.owner;
    }
    /**
     * @dev get the domains of an address
     * @param _owner the owner of the domains
     * @return Domains the domains owned by this address
     */

    function domainsOf(address _owner) external view returns (string[] memory Domains) {
        Domains = domainLib._storage().ownerToDomains[_owner];
    }

    /**
     * internal functions ***************
     */

    function _resetForSale(string calldata _domain) internal {
        domainLib._storage().domainForSale[_domain] = forSale(false, typeSale.defaultEnum);
    }

    function _updateAuctionFinal(string calldata _domain) internal {
        auctionInfo memory auc = domainLib._storage().auction[_domain];
        if (auc.currentPayed < auc.lowerPrice) {
            // remove the domain from the auction
            domainLib._storage().auction[_domain] = auctionInfo(address(0), address(0), 0, 0, 0, 0);
            // remove the domain from for sale
            _resetForSale(_domain);
        } else {
            require(auc.lastBuyer != address(0));
            // update the owner from of the domain;
            domainLib._storage().domainToInfo._updateOwner(_domain, auc.lastBuyer);
            // remove domain from auction
            domainLib._storage().auction[_domain] = auctionInfo(address(0), address(0), 0, 0, 0, 0);
            // remove the domain from for sale :
            _resetForSale(_domain);
            // send eth to the original owner;
            (bool ok,) = auc.owner.call{value: auc.currentPayed}("");
            require(ok, "failed to pay the original owner");
        }
    }

    function _auction(string memory _domain, uint256 _lowerPrice, uint256 duration) internal returns (bool) {}
    function _fixedPriceSell(string memory _domain, uint256 price) internal returns (bool) {}
}
