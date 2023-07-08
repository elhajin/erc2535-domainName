//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./domainLib.sol";

struct Storage {
    mapping(string domainName => domainInfo info) domainToInfo; // get a domain name info
    mapping(address owner => string[] domainName) ownerToDomains; // get the domain name of an address
    uint256 currentId; // the id for last domain name
    mapping(string domainName => forSale) domainForSale; // check if the domain name for sale
    mapping(string domainName => auctionInfo) auction;
    mapping(string DomainName => fixedPriceInfo) fixedPrice;
}

error NotValidDomainName();
error OwnerShipExpired();
error NotValidPaymentAmount(uint256 price, uint256 payed);
error DomainExpired();

contract domainNames {
    using domainLib for mapping(string => domainInfo);

    Storage s;

    modifier Expired(string memory _domain){
        if (s.domainToInfo[_domain].buyedAt + s.domainToInfo[_domain].ownerShipPeriod >= block.timestamp){
            s.domainToInfo[_domain].owner = address(0);
            s.domainToInfo[_domain].buyedAt = 0;
            s.domainToInfo[_domain].ownerShipPeriod = 0;
        }
        _;
       
    }

    /**
     * @dev this function is allow any user to buy a domain if it's available
     */
    function buyDomain(string memory _domain, uint8 _years) external payable Expired(_domain)returns (bool success) {
        // check if the domain is available , and it's length is less then 32bytes
        s.domainToInfo._checkDomain(_domain);
        uint128 price;
        // when the domain not for sale : 
        if (!s.domainForSale[_domain].forSale) {
            // get the domain price depends on how many years;
            price = domainLib._getDiscount(domainLib._getDomainPrice(_domain), _years);
            // check the msg.value is equal or more than the nedded price
            if (msg.value >= price) {
                uint Id = s.domainToInfo[_domain].id == 0? s.currentId : s.domainToInfo[_domain].id;
                s.domainToInfo._setDomain(_domain,msg.sender,_years,Id);
                
            } else {
                revert NotValidPaymentAmount(price, msg.value);
            }
        // when domain for sale : 
        }
        else if (s.domainForSale[_domain].forSale) {
            // when type of domain sale is fixedPrice : 
           if (s.domainForSale[_domain].typeSale == typeSale.typeFixedPrice){
                price = s.fixedPrice[_domain].price;
                if (msg.value >= price) {
                    s.domainToInfo._updateOwner(_domain,msg.sender);
                    delete s.fixedPrice[_domain];
                    (bool ok,) = s.fixedPrice[_domain].owner.call{value :msg.value}("");
                    require(ok, "failed to send eth to the actual owner");
                    
                }else {
                revert NotValidPaymentAmount(price, msg.value);
                
                }
            } 
            // when the type of domain sale is auction: 
            else if (s.domainForSale[_domain].typeSale == typeSale.typeAuction){

            }

        }
        // store the new domain to the address of msg.sender;
        //
    }

    function sellDomain() external returns (bool success) {}

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
        domainInfo memory _ownerOf = s.domainToInfo[_domain];
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
        Domains = s.ownerToDomains[_owner];
    }

    /**
     * internal functions ***************
     */

     function _auctionCheck(auctionInfo memory ss,string memory _domain) internal  returns (auctionInfo memory ) {
        
        if (ss.owner == address(0)) revert NoAuctionAvailable();
        if (ss.startedAt< block.timestamp || ss.startedAt + ss.period > block.timestamp) revert OutOfTime();
    }

    function _auction(string memory _domain, uint256 _lowerPrice, uint256 duration) internal returns (bool) {}
    function _fixedPriceSell(string memory _domain, uint256 price) internal returns (bool) {}
}
