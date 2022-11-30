// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {StringUtils} from "../resources/StringUtils.sol";
// We import another help function
import "@openzeppelin/contracts/utils/Base64.sol";

error Unauthorized();
error AlreadyRegistered();
error InvalidName(string name);
// We inherit the contract we imported. This means we'll have access
// to the inherited contract's methods.
contract Domains is ERC721URIStorage {
    // Add this at the top of your contract next to the other mappings
    mapping (uint => string) public names;
    mapping (uint => uint) public domainPrice;
    mapping(string => address) public domains;

    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    address payable public owner;

    function getAllNames() public view returns (string[] memory) {
    string[] memory allNames = new string[](_tokenIds.current());
    for (uint i = 0; i < _tokenIds.current(); i++) {
        allNames[i] = names[i];
    }
    return allNames;
    }

    modifier onlyOwner() {
    require(isOwner());
    _;
    }

    function valid(string calldata name) public pure returns(bool) {
      return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }

    function isOwner() public view returns (bool) {
    return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw Matic");
    } 

    constructor() ERC721 ("Baro Name Service", "BNS") payable {
      owner = payable(msg.sender);
      tld = ".baro";
      domainPrice[0]=3 * 10 **17;
      domainPrice[1]=2 * 10 **17;
      domainPrice[2]=1 * 10 **17;
    }

    function register(string calldata name,string calldata image) public payable {
      //require(domains[name] == address(0));
      if (domains[name] != address(0)) revert AlreadyRegistered();
      if (!valid(name)) revert InvalidName(name);
      uint256 _price = price(name);

      require(msg.value >= _price, "Not enough Matic paid");
      
      // Combine the name passed into the function  with the TLD
      string memory _name = string(abi.encodePacked(name, ".", tld));
      uint256 newRecordId = _tokenIds.current();

      // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
      string memory json = Base64.encode(
        abi.encodePacked(
          '{"name": "',_name, '", "description": "A domain on the Baro Name Service", "image": ', image,'"}'
        )
      );
      string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));
      _safeMint(msg.sender, newRecordId);
      _setTokenURI(newRecordId, finalTokenUri);
      domains[name] = msg.sender;
      names[newRecordId] = name;
      _tokenIds.increment();
    }
  
    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns(uint) {
      uint len = StringUtils.strlen(name);
      require(len > 0);
      if (len == 3) {
        return domainPrice[0]; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
      } else if (len == 4) {
        return domainPrice[1]; // To charge smaller amounts, reduce the decimals. This is 0.3
      } else {
        return domainPrice[2];
      }
    }
    
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function changePrice(uint index, uint price) public  onlyOwner{
        domainPrice[index] = price;
    }


}