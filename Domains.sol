// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/access/AccessControl.sol";
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
contract Domains is ERC721URIStorage, AccessControl {
    // Add this at the top of your contract next to the other mappings
    bytes32 public constant APP_ROLE = keccak256("APP_ROLE");
    mapping (uint => string) public names;
    mapping (uint => uint) public domainPrice;
    mapping(string => address) public domains;


    constructor(address _addressAdmin) ERC721 ("Baro Name Service", "BNS") payable {
        _grantRole(DEFAULT_ADMIN_ROLE, _addressAdmin);
        _grantRole(APP_ROLE,_addressAdmin);
        owner = payable(_addressAdmin);
        tld = ".baro";
        domainPrice[0]=0;
        domainPrice[1]=0;
        domainPrice[2]=0;
        maxRange=25;
      }
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    address payable public owner;
    uint256 public maxRange;

    function getAllNames() public view returns (string[] memory) {
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
        }
        return allNames;
    }

    function valid(string memory _name) public view returns(bool) {
      return StringUtils.strlen(_name) >= 3 && StringUtils.strlen(_name) <= maxRange;
    }

    function withdraw() public  onlyRole(DEFAULT_ADMIN_ROLE) {
    uint amount = address(this).balance;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw Matic");
    } 

    function register(string calldata _name,string calldata _tokenURI) public payable  {
     string memory name = string(abi.encodePacked(_name, tld));
      if (domains[name] != address(0)) revert AlreadyRegistered();
      if (!valid(name)) revert InvalidName(name);
      uint256 _price = price(_name);

      require(msg.value >= _price, "Not enough Matic paid");
      
      uint256 newRecordId = _tokenIds.current();


      _safeMint(msg.sender, newRecordId);
      _setTokenURI(newRecordId, _tokenURI);
      domains[name] = msg.sender;
      names[newRecordId] = name;
      _tokenIds.increment();
    }
  
    // This function will give us the price of a domain based on length
    function price(string calldata _name) public view returns(uint) {
      uint len = StringUtils.strlen(_name);
      require(len > 0);
      if (len == 3) {
        return domainPrice[0]; 
      } else if (len == 4) {
        return domainPrice[1]; 
      } else {
        return domainPrice[2];
      }
    }

    function setAddress(address _address,string calldata _name) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
      domains[_name] = _address;
    }

     function setMaxRange(uint256 _newRange) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
      maxRange=_newRange;
    }
    
    
    function getAddress(string calldata _name) public view returns (address) {
        return domains[_name];
    }

    function changePrice(uint _index, uint _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        domainPrice[_index] = _price;
    }


}