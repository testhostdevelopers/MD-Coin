// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DogeCoin {
    function mint(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
}

contract MSDogeSig {
    DogeCoin public token;

    struct RequestStruct {
        bool isActive;
        bool isClosed;
        bool isSent;
        address createdBy;
        address dealedBy;
        address to;
        uint256 value;
        uint256 index;
    }

    struct AirDropStruct {
        address addresses;
        uint256 balances;
    }
    
    RequestStruct[] public transferList;
    AirDropStruct[] public airDropList;

    RequestStruct public burnRequest;
    
    mapping(address => bool) public owners;
    address[] public ownArray;
    uint256 transferedAmount;
    uint256 cancelTransferNumber;
    uint256 cancelBurnNumber;
    
    modifier onlyOwners() {
        require(owners[msg.sender]);
        _;
    }


    function setTokenAddress(address tokenAddress) private onlyOwners {
        token = DogeCoin(tokenAddress);
    }

    constructor(address[] memory _owners, address tokenAddress) {
        require(_owners.length == 3, "Owners are not 3 addresses" );
        for (uint i = 0; i < _owners.length; i ++) owners[_owners[i]] = true;
        setTokenAddress(tokenAddress);
    }

    // start transfer part
    function newTransferRequest(address to, uint256 value) public onlyOwners {
        RequestStruct memory transferRequest = RequestStruct({
            to: to,
            value: value,
            isClosed: false,
            isSent: false,
            isActive: true,
            index: transferList.length,
            createdBy: msg.sender,
            dealedBy: msg.sender
        });
        
        transferList.push(transferRequest);
    }

    function getRequestLength() public view returns(uint) {
        return transferList.length;    
    }
    
    function getTransferItem(uint idx) public view returns(RequestStruct memory item) {
        return transferList[idx];
    }
    
    function approveTransferRequest(uint idx) public onlyOwners  {
        require(transferList[idx].isActive);
        sendTransferRequest(idx);
        
    }

    function approveTransferListRequest(uint[] memory list) public onlyOwners {
        for (uint i = 0; i < list.length; i ++) {
            require(sendTransferRequest(list[i]));
        }
    }
    
    function declineTransferListRequest(uint[] memory list) public onlyOwners {
        for (uint i = 0; i < list.length; i ++) {
            require(declineTransferRequest(list[i]));
        }
    }
    
    function declineTransferRequest(uint idx) public onlyOwners returns(bool) {
        require(transferList[idx].isActive);
        closeTransferRequest(idx, false);
        cancelTransferNumber ++;
        return true;
    }

    function sendTransferRequest(uint idx) private onlyOwners returns(bool) {
        require(transferList[idx].isActive);
        token.transferFrom(transferList[idx].createdBy, transferList[idx].to, transferList[idx].value);
        transferedAmount += transferList[idx].value;
        closeTransferRequest(idx, true);
        return true;
    }
    
    function closeTransferRequest(uint idx, bool status) private onlyOwners {
        transferList[idx].dealedBy = msg.sender;
        transferList[idx].isActive = false;
        transferList[idx].isClosed = true;
        transferList[idx].isSent = status;
    }
    // end transfer part

    // start burn part
    function newBurnRequest(uint256 value) public onlyOwners {
        require(!burnRequest.isActive);
        uint256 ownBalance = token.balanceOf(msg.sender);
        require(value <= ownBalance);

        burnRequest = RequestStruct({
            to: msg.sender,
            value: value,
            isActive: true,
            isClosed: false,
            isSent: false,
            index: 0,
            createdBy: msg.sender,
            dealedBy: msg.sender
        });
    }

    function approveBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        sendBurnRequest();
    }

    function declineBurnRequest() public onlyOwners {
        require(burnRequest.isActive);
        cancelBurnNumber ++;
        closeBurnRequest(false);
    }

    function sendBurnRequest() private {
        token.burnFrom(burnRequest.createdBy, burnRequest.value);
        closeBurnRequest(true);
    }

    function closeBurnRequest(bool status) private {
        burnRequest.dealedBy = msg.sender;
        burnRequest.isActive = false;
        burnRequest.isClosed = true;
        burnRequest.isSent = status;
    }
    // end burn part

    function airDrop(AirDropStruct[] calldata list) public onlyOwners {
        for (uint i = 0; i < list.length; i++) {
            token.transferFrom(msg.sender, list[i].addresses, list[i].balances);
            transferedAmount += list[i].balances;
            airDropList.push(AirDropStruct(list[i].addresses, list[i].balances));
        }
    }
    
    function getTransferedAmount() public onlyOwners view returns (uint256) {
        return transferedAmount;
    }
    
    function getRequestList() public onlyOwners view returns (RequestStruct[] memory list) {
        return transferList;
    }
    
    function getBurnRequest() public view returns(RequestStruct memory item, uint256 cancel) {
        return (burnRequest, cancelBurnNumber);
    }
    
    function getAirDropList() public onlyOwners view returns(AirDropStruct[] memory list) {
        return airDropList;
    }
    
    function getLatestTransferRequest() public onlyOwners view returns(RequestStruct memory item, uint256 cancel) {
        RequestStruct memory sendItem;
        if (transferList.length > 0) sendItem = transferList[transferList.length - 1];
        return (sendItem, cancelTransferNumber);
    }
}