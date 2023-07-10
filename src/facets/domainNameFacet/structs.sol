//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct domainInfo {
    address owner;
    uint256 buyedAt;
    uint256 ownerShipPeriod;
    uint256 id;
}

struct auctionInfo {
    address owner;
    address lastBuyer;
    uint256 startedAt;
    uint256 period;
    uint256 lowerPrice;
    uint256 currentPayed;
}

struct fixedPriceInfo {
    address owner;
    uint128 price;
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
    mapping(string domainName => domainInfo info) domainToInfo; // get a domain name info
    mapping(address owner => string[] domainName) ownerToDomains; // get the domain name of an address
    uint256 currentId; // the id for last domain name
    mapping(string domainName => forSale) domainForSale; // check if the domain name for sale
    mapping(string domainName => auctionInfo) auction;
    mapping(string DomainName => fixedPriceInfo) fixedPrice;
}
