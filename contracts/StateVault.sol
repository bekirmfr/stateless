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
    uint private entityId;

    mapping(uint => bytes32) private data;
    mapping(uint => mapping(bytes32 => Variable)) private variables;
    mapping(address => uint) private entities;
    constructor(){
        owner = msg.sender;
    }
    function RegiterEntity(address _entity) public returns(uint){
        require(msg.sender == owner, "Only owner!");
        entities[_entity] = ++entityId;
        return entityId;
    }
    function Var(string memory _name, DATATYPE _dataType) internal{
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        Variable storage v = variables[entity][keccak256(abi.encode(_name))];
        v.name = _name.stringToBytes32();
        v.dataType = _dataType;
        v.isDeclared = true;
        v.isKey = false;
        v.isConstant = false;
    }
    function String(string memory _name) public{
        Var(_name, DATATYPE.STRING);
    }
    function Integer(string memory _name) public{
        Var(_name, DATATYPE.INTEGER);
    }
    function Address(string memory _name) public{
        Var(_name, DATATYPE.ADDRESS);
    }
    function Bytes(string memory _name) public{
        Var(_name, DATATYPE.BYTES);
    }

    function set(string memory _name, bytes memory _data, DATATYPE _dataType) internal {
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        Variable storage v = variables[entity][keccak256(abi.encode(_name))];
        require (v.isDeclared, "Variable is nor declared!");
        require (v.dataType == _dataType, "Incorrect data type!");
        uint32 remainder = uint32(_data.length % 32);
        uint8 chunkCount = uint8(_data.length / 32);
        if (remainder > 0) chunkCount++;
        
        for (uint i; i < chunkCount; i++){
            uint start = i*32;
            uint end = (i+1)*32;
            if(end > _data.length) end = _data.length;
            bytes32 chunk = bytes32(_data.substring (start, end));
            data[dataId] = chunk;
            v.dataPointers.push(dataId);
            dataId++;
        }
    }

    function setAddress(string memory _name, address _data) public {
        set(_name, abi.encode(_data), DATATYPE.ADDRESS);
    }
    function setBytes(string memory _name, bytes memory _data) public {
        set(_name, _data, DATATYPE.BYTES);
    }

    function setInteger(string memory _name, int _data) public {
        set(_name, abi.encode(_data), DATATYPE.INTEGER);
    }

    function setString(string memory _name, string memory _string) public {
        set(_name, abi.encode(_string), DATATYPE.STRING);
    }

    function get(string memory _name, DATATYPE _dataType) internal view returns (bytes memory){
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        Variable storage v = variables[entity][keccak256(abi.encode(_name))];
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
    function getBytes(string memory _name) public view returns (bytes memory ){
        return get(_name, DATATYPE.BYTES);
    }
    function getAddress(string memory _name) public view returns (address _address){
        bytes memory _data = get(_name, DATATYPE.ADDRESS);
        (_address) = abi.decode(_data, (address));
        return _address;
    }
    function getInt(string memory _name) public view returns (int _int){
        bytes memory _data = get(_name, DATATYPE.INTEGER);
        (_int) = abi.decode(_data, (int));
        return _int;
    }
    function getString(string memory _name) public view returns (string memory _string){
        bytes memory _data = get(_name, DATATYPE.STRING);
        (_string) = abi.decode(_data, (string));
        return _string;
    }
}