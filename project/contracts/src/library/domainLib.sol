//SPDX-License-Identifier: MIT
// set the id to 1
pragma solidity ^0.8.19;
struct domainInfo {
    address owner;
    uint256 buyedAt;
    uint256 ownerShipPeriod;
    uint256 id;
}

struct auctionInfo {
    address  owner;
    address lastBuyer;
    uint256 startedAt;
    uint256 period;
    uint256 lowerPrice;
    uint256 currentPayed;
}

struct fixedPriceInfo {
    address owner;
    uint price;
    uint256 expiredAt;
}

struct forSale {
    bool forSale;
    typeSale typeSale;
}

enum typeSale {
    defaultEnum,
    typeAuction,
    typeFixedPrice
}

//************************** MAIN STORAGE ***********************/
struct Storage {
    mapping(bytes32 domainName => domainInfo info) domainToInfo; // get a domain name info
    uint256 currentId ; // the id for last domain name
    mapping(bytes32 domainName => forSale) domainForSale; // check if the domain name for sale
    mapping(bytes32 domainName => auctionInfo) auction;
    mapping(bytes32 DomainName => fixedPriceInfo) fixedPrice;
    mapping(bytes32 => bool) available; // mapping that check a domain name is available 
}
error NotValidDomainName();
error NotAvailableDomain();
error AuctionNotActiveYet(uint startAt);
error NotEnoughFund(uint latestPrice);
error NotDomainOwner();
error NotValidTypeSale();
error DomainNameTaken();
error NotValidYears();
error NotValidAmount();
error CantRevokeAnActiveAuction();
/**
    when domain is available : 
        1. when it's for sale
        2. when it does not have an owner
    when domain is not available :
        1. when the domain have and owner and not for sale 
    when domain for sale : 
        1. function _owner of not return the owner untile the domain not for sale 
    when buy : 
        1. check if the domain available (modifier)
        2. chekc if the domain not for sale 
            a.calcultate the price , check the msg.value , assing the domain to the msg.sender
        3. if the domain for sale :
            a. fixed price 
                - check msg.value == fee +price, 
                -  make the domain not available , remove it from the sale and fixed price ,change owner to msg.sender,send price to the owner
            b. auction : 
                - the auction will be updated if it's final , 
                - check that the auction started 
                - check that the msg.value, >= the gratest paid amount , 
                    - if so : check if there is a buyer before it , update it to msg.sender and send   */
library domainLib {
    ////////// events /////////////////
    event DomainBuyed(string indexed Domain,address indexed from, address indexed to, uint price);
    event DomainForSaleAuction(string indexed Domain,address indexed Owner, uint LowerPrice);
    event DomainForSale(string indexed Domain,address indexed Owner,uint indexed Price);
    event RevokeFromSale(string indexed Domain);
    event AuctionClosed(address indexed currentOwner, string indexed domain);
    ////////// storage location in the diamond contract ///////////
    bytes32 internal constant MAIN_STORAGE_LOCATION = bytes32(uint256(keccak256("sToRaGe.LoCaTiOn.DoMaIn.FaCeT")) - 1);
    //////// constant ///////////
    uint64 public constant LIFE_TIME_DOMAIN = 0.1 ether;
    uint256 public constant LIFE_TIME_OWNERSHIP = ~uint256(0);
    uint256 public constant YEAR = 365 days;
    function __init__() internal {
        s().currentId = 1;
    }
    //********** modifiers **********//
    modifier _checkDomain(string calldata _domain) {
        // if the domain is available (it will revert if the domain length not valid)
        if(!_isDomainAvailable(_domain)){
            _updateDomain(_domain);
        }
        _;
       
    }
    
    //******** state update functions *********//
    /**
    @dev function to buy a domain name if it's available
     */
    function buyDomain(string calldata _domain,uint msgvalue,uint8 _years) internal _checkDomain(_domain)  {
        bytes32 domain = bytes32(bytes(_domain));
        if (!s().domainForSale[domain].forSale) {
            // get the domain price ,
           (uint64 price,uint _Years) =  _domainPrice(_domain,_years);
            // check that the user provide the correct price
            if(msgvalue < price) revert NotEnoughFund(price);
            uint ID = s().domainToInfo[domain].id;
            if (s().domainToInfo[domain].id == 0) {
                ID = s().currentId; s().currentId++;
            }
            s().domainToInfo[domain]= domainInfo(msg.sender,block.timestamp,block.timestamp + (_Years *YEAR),ID);
            s().available[domain] = false;
            emit DomainBuyed(_domain, address(0), msg.sender, price);
            return;
        }
        else if(s().domainForSale[domain].forSale){
            if(s().domainForSale[domain].typeSale == typeSale.typeAuction){
                _updateAuctionLive(domain,msgvalue);
                return;
            }
            else if (s().domainForSale[domain].typeSale == typeSale.typeFixedPrice){
                if (_sellFixedPrice(domain,msgvalue)) return;
            }
        }
    }
    function sellDomain(string calldata _domain,typeSale _type,uint _price,uint _start,uint _period) internal 
        _checkDomain(_domain) {
         if (msg.sender!= s().domainToInfo[bytes32(bytes(_domain))].owner) revert NotDomainOwner();
        bytes32 dom = bytes32(bytes(_domain));
        if (_type == typeSale.typeAuction){
            _setAuction(dom, _price, _start, _period);
            emit DomainForSaleAuction(_domain,s().auction[dom].owner , _price);
            return;
        }
        else if (_type == typeSale.typeFixedPrice){
            _setFixedPrice(dom,_price,_period);
            emit DomainForSale(_domain,s().fixedPrice[dom].owner,_price);
            return;
        }
        else revert NotValidTypeSale();
    }
    function revokeDomain(string memory _domain ) internal  {
        bytes32 dom = bytes32(bytes(_domain));
        if (msg.sender != s().domainToInfo[dom].owner) revert NotDomainOwner();
        auctionInfo memory auc = s().auction[dom];
        if (s().domainForSale[dom].typeSale == typeSale.typeAuction && auc.currentPayed >= auc.lowerPrice && auc.lastBuyer != address(0)) {
           revert CantRevokeAnActiveAuction();
        }else {_resetForSale(dom);
        s().available[dom] = false;
        emit RevokeFromSale(_domain);
        return;}
    } 

    function closeAuction(string memory _domain) internal {
        bytes32 dom = bytes32(bytes(_domain));
       if (msg.sender != s().domainToInfo[dom].owner) revert NotDomainOwner();
        auctionInfo memory auc = s().auction[dom];
       if (s().domainForSale[dom].typeSale == typeSale.typeAuction && auc.currentPayed >= auc.lowerPrice && auc.lastBuyer != address(0)){
            _resetForSale(dom);
            _updateOwner(dom, auc.lastBuyer);
            s().available[dom]  = false;
            //send token to the last buyer : 
            (bool ok,) = payable(auc.owner).call{value: auc.currentPayed}("");
            require(ok, "failed to send fund");
            emit AuctionClosed(auc.lastBuyer,_domain);
       }else{
        _resetForSale(dom);
        s().available[dom] = false;
        emit AuctionClosed(auc.owner,_domain);
       }


    }

    // helper functions : 
    
    function _updateDomain(string calldata _domain) private{
        //check if the domain expired already revert
        bytes32 dom= bytes32(bytes(_domain));
        if (s().domainToInfo[dom].owner != address(0)){
            if (s().domainToInfo[dom].buyedAt + s().domainToInfo[dom].ownerShipPeriod < block.timestamp){
                _resetDomainInfo(dom);
                _resetForSale(dom);
                return ;
            }
        }
        if (s().domainForSale[dom].forSale){
            // check and update the sale info 
            if (s().domainForSale[dom].typeSale == typeSale.typeAuction){
                 if (s().auction[dom].startedAt + s().auction[dom].period < block.timestamp){
                     _updateAuctionFinal(dom);
                     }    
            }  
            else if (s().domainForSale[dom].typeSale == typeSale.typeFixedPrice){
                if(s().fixedPrice[dom].expiredAt > block.timestamp) {
                    _resetForSale(dom);
                    s().available[dom] = false;
                }

            } 
        }
        
        // check if the domain in sale and expired reset
       
    }
    /**
        @dev get a domainName price depends on the domain length and the ownership period in years
        @notice if you pass more then 10 _years you will own the domain for ever.
        @param _domain the domain name that you wanna calculate the price for 
        @param _years the ownership period in years
        @return price the price of the _domain for _years period 
     */
    function _domainPrice(string memory _domain,uint8 _years) internal pure returns (uint64 price,uint year) {
        if (_years == 0) revert NotValidYears();
        uint p;
        if (bytes(_domain).length >= 20) {
            p = 0.01 ether;
        }
        if (
            bytes(_domain).length >= 10
                && bytes(_domain).length < 20
        ) {
            p = 0.006 ether;
        } else if (bytes(_domain).length < 10) {
            p = 0.003 ether;
        }
        (price,year) = _getDiscount(uint64(p), _years);
    }
    function _getDiscount(uint64 _price, uint8 _years) private pure returns (uint64 price,uint year) {
        // get the percentage of _years * 7  from the price
        if (_years <= 10) {
            uint64 percentage = (_years) * 7 * price / 100;
            price = (_price + (_price - percentage) * _years);
            year = _years;
        } else {
            price = LIFE_TIME_DOMAIN;
            year = 100000;
        }
    } 
    /**
        @dev function that reset the domain info to zero value except for the id ,it's immutable for domain 
        @param domain the bytes32 format of the domain
     */
    function _resetDomainInfo(bytes32 domain) private {
        uint ID = s().domainToInfo[domain].id;
        s().domainToInfo[domain] = domainInfo(address(0),0,0,ID);
        s().available[domain] = true;
    }
    function _resetAuction(bytes32 _domain) private{
        s().auction[_domain] = auctionInfo(address(0), address(0), 0, 0, 0, 0);
    } 
    function _resetFixedPrice(bytes32 _domain) private{
        s().fixedPrice[_domain]= fixedPriceInfo(address(0),0,0);
    }
    function _resetForSale(bytes32 _domain) private{
       typeSale t=  s().domainForSale[_domain].typeSale;
        s().domainForSale[_domain] = forSale(false, typeSale.defaultEnum);
        if (t == typeSale.typeAuction) _resetAuction(_domain);
        else _resetFixedPrice(_domain);
        
    } 
    function _updateOwner(bytes32 _domain,address owner) private {
        s().domainToInfo[_domain].owner = owner;
    }
    function _updateAuctionLive(bytes32 _domain,uint msgvalue) internal {
        auctionInfo memory auc = s().auction[_domain] ;
        //check the the auction started : 
        if (auc.startedAt > block.timestamp) revert AuctionNotActiveYet(auc.startedAt);
        // when we have a last buyer : 
        if(auc.lastBuyer != address(0) && auc.currentPayed >= auc.lowerPrice){
            // check the msg.value.
            if (msgvalue <= auc.currentPayed) revert NotEnoughFund(auc.currentPayed);
            (address lastbuyer, uint refund) = (auc.lastBuyer,auc.currentPayed);
            auc.lastBuyer = msg.sender;
            auc.currentPayed = msgvalue;
            s().auction[_domain] = auc;
            //send token to the last buyer : 
            (bool ok,) = payable(lastbuyer).call{value: refund}("");
            require(ok, "failed to send fund");
            return;
        }
        // when we don't have lastBuyer: 
        else if (auc.lastBuyer == address(0) && auc.currentPayed == 0){
            if (msgvalue < auc.lowerPrice) revert NotEnoughFund(auc.lowerPrice);
            s().auction[_domain].lastBuyer = msg.sender;
            s().auction[_domain].currentPayed = msgvalue;
            return;
        }
      
        
    }
    function _updateAuctionFinal(bytes32 _domain) internal {
        auctionInfo memory auc = s().auction[_domain];
            _resetForSale(_domain);
        if (auc.currentPayed >= auc.lowerPrice &&auc.lastBuyer != address(0)) {
            // update the owner from of the domain;
            _updateOwner(_domain, auc.lastBuyer);
            s().available[_domain]  = false;
            // send eth to the original owner;
            (bool ok,) = payable(auc.owner).call{value: auc.currentPayed}("");
            require(ok, "failed to pay the original owner");
            emit DomainBuyed(string(abi.encodePacked(_domain)), auc.owner, auc.lastBuyer, auc.currentPayed);
        }
    }
    function _sellFixedPrice(bytes32 _domain,uint msgvalue) internal returns(bool) {
        fixedPriceInfo memory fix = s().fixedPrice[_domain];
        if(fix.price > msgvalue) revert NotEnoughFund(fix.price);
        (address previousOwner,uint refund) = (fix.owner,fix.price);
        // reset for sale .
        _resetForSale(_domain); 
        // update the owner 
        _updateOwner(_domain,msg.sender);
        s().available[_domain] = false;
        // send the eth to the owenr;
        (bool ok,) = payable(previousOwner).call{value:refund}("");
        require(ok,"failed to send tx");
        emit DomainBuyed(string(abi.encodePacked(_domain)), previousOwner, msg.sender, refund);
        return true ;
    }
    function _setAuction (bytes32 _domain,uint _lowerPrice,uint _startAt,uint _period ) internal {
        // put it for sale :
        s().domainForSale[_domain] = forSale(true,typeSale.typeAuction);
        s().available[_domain] = true;
        // put the domain in auction 
        s().auction[_domain] = auctionInfo(s().domainToInfo[_domain].owner,address(0),_startAt,_period,_lowerPrice,0);
    }
    function _setFixedPrice(bytes32 _domain,uint _price,uint _period) internal { 
        // put the domain for sale and make it available : 
        s().domainForSale[_domain] = forSale(true,typeSale.typeAuction);
        s().available[_domain] = true;
        // set the price :
        s().fixedPrice[_domain] = fixedPriceInfo(s().domainToInfo[_domain].owner,_price, block.timestamp + _period);
    }
    //////// storage function //////
    function s() internal pure returns(Storage storage _s) {
        bytes32 location = MAIN_STORAGE_LOCATION;
        assembly {
            _s.slot := location
        }
    }
    /////// view functions ////////
    function _ownerOf (string calldata _domain) internal view returns(address ){
        if (_isDomainAvailable(_domain)) return address(0);
        else return s().domainToInfo[bytes32(bytes(_domain))].owner;
        
    }
    function _domainForSale(string calldata _domain) internal view returns(bool){
        return s().domainForSale[bytes32(bytes(_domain))].forSale;
    }
    function _domainInfo (string calldata _domain) internal view returns(domainInfo memory info){
        return s().domainToInfo[bytes32(bytes(_domain))];
    }
    function _auctionInfo(string calldata _domain) internal view returns(auctionInfo memory info){
        if (bytes(_domain).length >32 ||bytes(_domain).length ==0 ) revert NotValidDomainName();
        return s().auction[bytes32(bytes(_domain))];
    }
    function _isDomainAvailable(string calldata _domain) internal view returns(bool){
        if (bytes(_domain).length >32 ||bytes(_domain).length ==0 ) revert NotValidDomainName();
        return s().available[bytes32(bytes(_domain))];
    }
    function _getDomainPrice(string calldata _domain,uint8 _years) internal view returns (uint price){
        if (!_isDomainAvailable(_domain)) revert  DomainNameTaken();
        else{
            // if the domain not for sale :
            if (!s().domainForSale[bytes32(bytes(_domain))].forSale){
               (price,) =  _domainPrice(_domain,_years);
            }else if (s().domainForSale[bytes32(bytes(_domain))].forSale) {
                if (s().domainForSale[bytes32(bytes(_domain))].typeSale == typeSale.typeAuction){
                    auctionInfo memory auc= s().auction[bytes32(bytes(_domain))] ;
                    price = auc.currentPayed < auc.lowerPrice ? auc.lowerPrice : auc.currentPayed;
                }else {
                    price = s().fixedPrice[bytes32(bytes(_domain))].price;
                }
            }
        }
    }
}