//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "../../library/domainLib.sol";
import "../../library/diamondLib.sol";
import {delegateCall} from "../../helperFunctions/delegatecall.sol";


contract domainNames is delegateCall  {

    constructor () {
        domainLib.__init__();
    }
    modifier onlyOwner() {
        diamondLib._checkOwnership();
        _;
    }

    function buyDomain(string calldata _domain,uint8 _years) payable external onlyDelegatecall returns(bool)  {
       domainLib.buyDomain(_domain, msg.value, _years);
        return true;
    }
    function sellDomain(string calldata _domain,typeSale _typeSale,uint _price,uint _startAt,
    uint _period) external onlyDelegatecall returns(bool){
        domainLib.sellDomain(_domain, _typeSale, _price, _startAt, _period);
        return true;
    }
    function revokeDomain(string memory _domain) external onlyDelegatecall(){
        domainLib.revokeDomain(_domain);
    }
    function closeAuction(string memory _domain) external onlyDelegatecall(){
        domainLib.closeAuction(_domain);
    }
    /**
       @dev function that allow the owner to withdraw the native token
       @notice it will revet if the balance of the contract less then the amount selected to withdraw
        */
    function Withdraw(uint amount) external onlyOwner onlyDelegatecall{
        if (address(this).balance < amount) revert NotValidAmount();
        (bool ok,) = payable(owner()).call{value: amount}("");
        require(ok,"failed to send eth");
    }


    ///////// read state function //////////
    /**
        @dev get the owner of a domain name
        @notice if the domain name is not owned buy anyone it will return address(0)
        @notice if the domain name is for sale it will return address(0) [the domain name that is forSale it's not owned by anyone until the sale
        expired or happend.]
        @param _domain the domain name 
        @return address the owner address of this domain
     */
    function ownerOf (string calldata _domain) external view returns(address ){
       return domainLib._ownerOf(_domain);
    }
    /**
        @dev check if the domain is available or not.
        @notice the available domain means that this domain can be buyed buy any one. 
        @notice the domains that is forSale are considered available domains 
        @notice "nonavailable" domain is the domain that have an owner and not for sale
        */
    function isDomainAvailable(string calldata _domain) external view returns (bool){
        return domainLib._isDomainAvailable(_domain);
    }
    /**
        @dev get a domain name price 
        @notice it will revert if the domain name not a valid lenght or taken.
        @param _domain the domain name that you wanna get the price 
     */
    function getDomainPrice(string calldata _domain,uint8 _years) external view returns(uint price){
        price = domainLib._getDomainPrice(_domain, _years);
    }
    /**
    @dev get the owner of the contract
     */
    function owner () public view returns(address _owner){
        _owner = diamondLib._storage().ownership;
    }


    

}
