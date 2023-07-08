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
    uint startedAt;
    uint period;
    uint lowerPrice;
    uint currentPrice;
}
struct fixedPriceInfo{
    address owner;
    uint128 price;
    uint expiredAt;
}
struct forSale {
    bool forSale;
    typeSale typeSale;
}

enum typeSale {
    typeAuction,
    typeFixedPrice
}

