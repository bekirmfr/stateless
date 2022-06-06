// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Stateless {

    uint private id;
    struct Variable{
        bytes32 name;
        uint8 dataType; // 0 -> bytes, 1 -> integer, 2 -> string, 3 -> address
        bool isDeclared;
        bool isKey;
        bool isConstant;
        uint[] dataPointers;
    }
    struct Array{
        bytes32 name;
        uint8 dataType; // 0 -> bytes, 1 -> integer, 2 -> string, 3 -> address
        bool isDeclared;
        bytes32[] elements;
    }

    mapping(uint => bytes32) private data;
    mapping(bytes32 => Variable) private variables;
    mapping(bytes32 => Array) private arrays;

    function declareVariable(string memory _name, uint8 _dataType, bool _isKey, bool _isConstant) internal{
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        v.name = stringToBytes32(_name);
        v.isDeclared = true;
        v.dataType = _dataType;
        v.isKey = _isKey;
        v.isConstant = _isConstant;
    }
    function declareArray(string memory _name, uint8 _dataType) internal{
        Array storage a = arrays[keccak256(abi.encodePacked(_name))];
        a.name = stringToBytes32(_name);
        a.isDeclared = true;
        a.dataType = _dataType;
    }

    function store(string memory _name, bytes memory _data) internal {
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        require (v.isDeclared, "Variable is nor declared!");
        uint32 remainder = uint32(_data.length % 32);
        uint8 chunkCount = uint8(_data.length / 32);
        if (remainder > 0) chunkCount++;
        for (uint i; i < chunkCount; i++){
            uint start = i*32;
            uint end = (i+1)*32;
            if(end > _data.length) end = _data.length;
            bytes32 chunk = bytes32(substring (_data, start, end));
            data[id] = chunk;
            v.dataPointers.push(id);
            id++;
        }
    }

    function store(string memory _name, address _data) internal {
        store(_name, abi.encode(_data));
    }

    function store(string memory _name, int _data) internal {
        store(_name, abi.encode(_data));
    }

    function store(string memory _name, string memory _string) internal {
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        require (v.dataType == 2, "Incorrect data type!");
        bytes memory _data = abi.encodePacked(_string);
        uint32 remainder = uint32(_data.length % 32);
        uint8 chunkCount = uint8(_data.length / 32);
        if (remainder > 0) chunkCount++;
        for (uint i; i < chunkCount; i++){
            uint start = i*32;
            uint end = (i+1)*32;
            if(end > _data.length) end = _data.length;
            bytes32 chunk = bytes32(substring (_data, start, end));
            data[id] = chunk;
            v.dataPointers.push(id);
            id++;
        }
    }

    function get(string memory _name) internal view returns (bytes memory){
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        //require (v.dataType == bytes1(uint8(0)));
        uint dataPointerCount = v.dataPointers.length;
        //bytes memory resultData;
        bytes memory temp;
        for(uint i = 0; i < dataPointerCount; i++){
            bytes32 chunk = data[v.dataPointers[i]];
            temp = abi.encodePacked(temp, chunk);
        }
        return temp;
    }

    function getAddress(string memory _name) internal view returns (address _addr1){
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        require (v.dataType == 3, "Incorrect data type!");
        bytes memory _data = get(_name);
        (_addr1) = abi.decode(_data, (address));
        return _addr1;
    }
    function getInt(string memory _name) internal view returns (int _int){
        Variable storage v = variables[keccak256(abi.encodePacked(_name))];
        require (v.dataType == 1, "Incorrect data type!");
        bytes memory _data = get(_name);
        (_int) = abi.decode(_data, (int));
        return _int;
    }

    function stringToBytes32(string memory self) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(self);
        require(tempEmptyStringTest.length <= 32, "Variable name can not exceed 32 bytes.");
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(self, 32))
        }
    }
    function bytes32ToString(bytes32 self) private pure returns (string memory) {
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = self[i];
        }
    return string(bytesArray);
    }

    function substring(bytes memory str, uint startIndex, uint endIndex) private pure returns (bytes memory) {
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = str[i];
    }
    return result;
    }
}
