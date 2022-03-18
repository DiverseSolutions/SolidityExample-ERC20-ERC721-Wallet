// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DiverseWallet {
  
  address[] public tokens;

  address[] public nftsAddress;
  uint[] public nftsTokenId;

  address public _owner;

  event TokenSent(address indexed _tokenAddress, address indexed _to, uint _amount);
  event TokenRecieved(address indexed _tokenAddress, address indexed _sender, uint amount);

  event NftSent(address indexed _nftAddress, address indexed _to, uint _tokenId);
  event NftRecieved(address indexed _nftAddress, address indexed _sender, uint _tokenId);

  event EtherSent(address indexed _to, uint _amount);
  event EtherRecieved(address indexed _sender, uint amount);

  constructor(){
    _owner = msg.sender;
  }

  // ETHER Token Related Functions
  function sendEtherToWallet() payable public{
    require(msg.value != 0 ether,"Sent Ether Cant Be 0");
    emit EtherRecieved(msg.sender,msg.value);
  }

  function sendWalletEtherToAddress(address _to,uint _amount) public onlyOwner returns(bool){
    require(_to != address(0),"To Address Cant Be 0");
    require(_amount <= address(this).balance ,"Amount Bigger Than Wallet Balance");

    bool result = payable(address(_to)).send(_amount);
    require(result == true,"Transfer From Wallet To User Failed");

    emit EtherSent(msg.sender,_amount);

    return result;
  }

  // ERC20 Token Related Functions

  function sendTokenFromWalletToAddress(address _tokenAddress,address _to,uint _amount) public onlyOwner returns(bool){
    require(_tokenAddress != address(0),"Token Address Cant Be 0");
    require(_to != address(0),"To Address Cant Be 0");

    IERC20 _token = IERC20(_tokenAddress);

    uint256 walletBalance = _token.balanceOf(address(this));
    require(walletBalance > _amount,"Amount Bigger Than Balance");

    bool result = _token.transfer(_to,_amount);
    require(result == true,"Transfer From Owner To Wallet Failed");

    emit TokenSent(_tokenAddress,_to,_amount);

    return result;
  }

  function sendTokenToWallet(address _tokenAddress,uint _amount) public returns(bool){
    require(_tokenAddress != address(0),"Token Address Cant Be 0");

    IERC20 _token = IERC20(_tokenAddress);

    uint256 userBalance = _token.balanceOf(msg.sender);
    require(userBalance > _amount,"Amount Bigger Than Balance");

    uint allowance = _token.allowance(msg.sender, address(this));
    require(allowance >= _amount,"Amount Bigger Than Allowance");
    bool result = _token.transferFrom(msg.sender,address(this),_amount);
    require(result == true,"Transfer From Owner To Wallet Failed");

    tokens.push(_tokenAddress);
    emit TokenRecieved(_tokenAddress,msg.sender,_amount);

    return result;
  }

  function getTokensLength() public view returns (uint) {
    return tokens.length;
  }

  function getTokenWalletBalance(address _tokenAddress) public view returns (uint256) {
    require(_tokenAddress != address(0),"Token Address Cant Be 0");

    IERC20 _token = IERC20(_tokenAddress);
    uint256 userBalance = _token.balanceOf(address(this));
    return userBalance;
  }

  // ERC721 NFT Related Functions

  function sendNftFromWalletToAddress(address _nftAddress,address _to,uint _tokenId) public onlyOwner {
    require(_nftAddress != address(0),"Nft Address Cant Be 0");
    require(_to != address(0),"To Address Cant Be 0");

    IERC721 _nft = IERC721(_nftAddress);

    address nftOwner = _nft.ownerOf(_tokenId);
    require(nftOwner == _to,"Not Owner Of NFT");

    _nft.transferFrom(address(this),_to,_tokenId);

    emit NftSent(_nftAddress,_to,_tokenId);

  }

  function sendNftToWallet(address _nftAddress,uint _tokenId) public{
    require(_nftAddress != address(0),"Token Address Cant Be 0");

    IERC721 _nft = IERC721(_nftAddress);

    address nftOwner = _nft.ownerOf(_tokenId);
    require(nftOwner == msg.sender,"Not Owner Of NFT");

    address approvedAccount = _nft.getApproved(_tokenId);
    require(approvedAccount == address(this),"Wallet Contract Not Approved For Transfer");

    _nft.transferFrom(msg.sender,address(this),_tokenId);

    nftsAddress.push(_nftAddress);
    
    nftsTokenId.push(_tokenId);

    emit NftRecieved(_nftAddress,msg.sender,_tokenId);


  }

  function getNftAddressLength() public view returns (uint) {
    return nftsAddress.length;
  }

  function getNftTokenIdLength() public view returns (uint) {
    return nftsTokenId.length;
  }

  // Account Related Functions
  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  modifier onlyOwner(){
    require(msg.sender == _owner,"Not Owner");
    _;
  }

  function setOwner(address _newAddress) public onlyOwner {
    require(_newAddress != address(0),"New Address Cant Be 0");
    require(_newAddress != _owner,"New Address Cant Be Current Owner");

    _owner = _newAddress;
  }

}
