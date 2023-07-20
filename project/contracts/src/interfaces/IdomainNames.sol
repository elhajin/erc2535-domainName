// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface domainNames {
    enum typeSale {ForSale, Auction}

    function buyDomain(string calldata _domain, uint8 _years) external payable returns (bool);

    function sellDomain(
        string calldata _domain,
        typeSale _typeSale,
        uint256 _price,
        uint256 _startAt,
        uint256 _period
    ) external returns (bool);

    function revokeDomain(string memory _domain) external;

    function closeAuction(string memory _domain) external;

    function Withdraw(uint256 amount) external;

    function ownerOf(string calldata _domain) external view returns (address);

    function isDomainAvailable(string calldata _domain) external view returns (bool);

    function getDomainPrice(string calldata _domain, uint8 _years) external view returns (uint256 price);

    function owner() external view returns (address);
}
