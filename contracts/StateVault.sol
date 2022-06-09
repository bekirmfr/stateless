// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Library.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract StateVault {
    using Library for *;

    address public owner;
    uint private dataId;
    uint[] public pointerBin;
    uint private entityId;

    mapping(uint => bytes32) public data;
    mapping(uint => mapping(bytes32 => iVariable)) public variables;
    mapping(address => uint) public entities;
    constructor(){
        owner = msg.sender;
    }
    function RegiterEntity(address _entity) public returns(uint){
        require(msg.sender == owner, "Only owner!");
        entities[_entity] = ++entityId;
        return entityId;
    }
    function Variable(string memory _name, DATATYPE _dataType) internal{
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        iVariable storage v = variables[entity][keccak256(abi.encode(_name))];
        v.name = _name.stringToBytes32();
        v.dataType = _dataType;
        v.isDeclared = true;
        v.isKey = false;
        v.isConstant = false;
    }
    function _Boolean(string memory _name) public{
        Variable(_name, DATATYPE.BOOLEAN);
    }
    function _String(string memory _name) public{
        Variable(_name, DATATYPE.STRING);
    }
    function _Integer(string memory _name) public{
        Variable(_name, DATATYPE.INTEGER);
    }
    function _Address(string memory _name) public{
        Variable(_name, DATATYPE.ADDRESS);
    }
    function _Bytes(string memory _name) public{
        Variable(_name, DATATYPE.BYTES);
    }

    function set(string memory _name, bytes memory _data, DATATYPE _dataType) internal {
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        iVariable storage v = variables[entity][keccak256(abi.encode(_name))];
        require (v.isDeclared, "Variable is nor declared!");
        require (v.dataType == _dataType, "Incorrect data type!");
        uint32 remainder = uint32(_data.length % 32);
        uint8 chunkCount = uint8(_data.length / 32);
        if (remainder > 0) chunkCount++;
        //recycle used pointers
        while(v.dataPointers.length > 0){
            uint pointer = v.dataPointers[v.dataPointers.length -1];
            pointerBin.push(pointer);
            v.dataPointers.pop();
            delete data[pointer];
        }
        for (uint i; i < chunkCount; i++){
            uint start = i*32;
            uint end = (i+1)*32;
            if(end > _data.length) end = _data.length;
            bytes32 chunk = bytes32(_data.substring (start, end));
            //If pointerBin has recycled pointers, use them first.
            if(pointerBin.length > 0){
                uint pointer = pointerBin[pointerBin.length -1];
                pointerBin.pop();
                v.dataPointers.push(pointer);
                data[pointer] = chunk;
            }else{
                data[++dataId] = chunk;
                v.dataPointers.push(dataId);
            }
            
        }
    }
    
    function setBytes(string memory _name, bytes memory _data) external {
        set(_name, _data, DATATYPE.BYTES);
    }
    function setInteger(string memory _name, int _data) public {
        set(_name, abi.encode(_data), DATATYPE.INTEGER);
    }
    function setBoolean(string memory _name, bool _data) public {
        set(_name, abi.encode(_data), DATATYPE.BOOLEAN);
    }
    function setAddress(string memory _name, address _data) public {
        set(_name, abi.encode(_data), DATATYPE.ADDRESS);
    }
    function setString(string memory _name, string memory _data) public {
        set(_name, abi.encode(_data), DATATYPE.STRING);
    }

    function get(string memory _name, DATATYPE _dataType) internal view returns (bytes memory){
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        iVariable storage v = variables[entity][keccak256(abi.encode(_name))];
        require(v.isDeclared, "Variable not declared!");
        require(v.dataType == _dataType, "Variable not declared!");
        uint dataPointerCount = v.dataPointers.length;
        //bytes memory resultData;
        bytes memory temp;
        for(uint i = 0; i < dataPointerCount; i++){
            bytes32 chunk = data[v.dataPointers[i]];
            temp = abi.encodePacked(temp, chunk);
        }
        return temp;
    }
    
    function Bytes(string memory _name) external view returns (bytes memory ){
        return get(_name, DATATYPE.BYTES);
    }
    function Boolean(string memory _name) external view returns (bool _bool){
        bytes memory _data = get(_name, DATATYPE.BOOLEAN);
        (_bool) = abi.decode(_data, (bool));
        return _bool;
    }
    function Address(string memory _name) external view returns (address _address){
        bytes memory _data = get(_name, DATATYPE.ADDRESS);
        (_address) = abi.decode(_data, (address));
        return _address;
    }
    function Integer(string memory _name) external view returns (int _int){
        bytes memory _data = get(_name, DATATYPE.INTEGER);
        (_int) = abi.decode(_data, (int));
        return _int;
    }
    function String(string memory _name) external view returns (string memory _string){
        bytes memory _data = get(_name, DATATYPE.STRING);
        (_string) = abi.decode(_data, (string));
        return _string;
    }
}
