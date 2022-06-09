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
    uint[] public dataBin;
    uint private entityId;

    mapping(uint => bytes32) public data;
    mapping(uint => mapping(bytes32 => Variable)) public variables;
    mapping(address => uint) public entities;
    constructor(){
        owner = msg.sender;
    }
    function RegiterEntity(address _entity) public returns(uint){
        require(msg.sender == owner, "Only owner!");
        entities[_entity] = ++entityId;
        return entityId;
    }
    
    function set(string memory _name, bytes memory _data, DATATYPE _dataType) internal {
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        sVariable storage v = variables[entity][keccak256(abi.encode(_name))];
        require (v.isDeclared, "Variable is nor declared!");
        require (v.dataType == _dataType, "Incorrect data type!");
        uint32 remainder = uint32(_data.length % 32);
        uint8 chunkCount = uint8(_data.length / 32);
        if (remainder > 0) chunkCount++;
        //recycle used pointers
        while(v.dataPointers.length > 0){
            uint pointer = v.dataPointers[v.dataPointers.length -1];
            dataBin.push(pointer);
            v.dataPointers.pop();
            delete data[pointer];
        }
        for (uint i; i < chunkCount; i++){
            uint start = i*32;
            uint end = (i+1)*32;
            if(end > _data.length) end = _data.length;
            bytes32 chunk = bytes32(_data.substring (start, end));
            //If dataBin has recycled pointers, use them first.
            if(dataBin.length > 0){
                uint pointer = dataBin[dataBin.length -1];
                dataBin.pop();
                v.dataPointers.push(pointer);
                data[pointer] = chunk;
            }else{
                data[++dataId] = chunk;
                v.dataPointers.push(dataId);
            }
        }
    }
    function Variable(string memory _name, DATATYPE _dataType) internal{
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        Variable storage v = variables[entity][keccak256(abi.encode(_name))];
        v.name = _name.stringToBytes32();
        v.dataType = _dataType;
        v.isDeclared = true;
        v.isKey = false;
        v.isConstant = false;
    }
    function _Boolean(string calldata _name) public{
        Variable(_name, DATATYPE.BOOLEAN);
    }
    function _String(string calldata _name) public{
        Variable(_name, DATATYPE.STRING);
    }
    function _Integer(string calldata _name) public{
        Variable(_name, DATATYPE.INTEGER);
    }
    function _Address(string calldata _name) public{
        Variable(_name, DATATYPE.ADDRESS);
    }
    function _Bytes(string calldata _name) public{
        Variable(_name, DATATYPE.BYTES);
    }
    
    function getVar(string memory _name, DATATYPE _dataType) internal view returns (sVariable storage v){
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        v = variables[entity][keccak256(abi.encode(_name))];
        require(v.isDeclared, "Variable not declared!");
        require(v.dataType == _dataType, "Variable not declared!");
        return v;
    }
    
    function Bytes(string memory _name) public view returns (sBytes memory){
        return sBytes(getVar(_name, DATATYPE.BYTES));
    }
    function Boolean(string memory _name) public view returns (sBoolean memory){
        return sBoolean(getVar(_name, DATATYPE.BOOLEAN));
    }
    function Address(string memory _name) public view returns (sAddress memory){
        return sAddress(getVar(_name, DATATYPE.ADDRESS));
    }
    function Integer(string memory _name) public view returns (sInteger memory){
        return sInteger(getVar(_name, DATATYPE.INTEGER));
    }
    function String(string memory _name) public view returns (sString memory){
        return sString(getVar(_name, DATATYPE.STRING));
    }
    function setBytes(string memory _name, bytes memory _data) public {
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
    function setString(string memory _name, string memory _string) public {
        set(_name, abi.encode(_string), DATATYPE.STRING);
    }
}
