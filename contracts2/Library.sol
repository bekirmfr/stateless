//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

enum DATATYPE {BOOLEAN, BYTES, INTEGER, STRING, ADDRESS}
struct sVariable{
    bytes32 name;
    DATATYPE dataType; // 0 -> bytes, 1 -> integer, 2 -> string, 3 -> address
    bool isDeclared;
    bool isKey;
    bool isConstant;
    uint[] dataPointers;
}
struct sAddress{
    sVariable variable;
}
struct sBoolean{
    sVariable variable;
}
struct sInteger{
    sVariable variable;
}
struct sBytes{
    sVariable variable;
}
struct sString{
    sVariable variable;
}

library Library {
    function get(bytes32 _name, DATATYPE _dataType) internal view returns (bytes memory){
        uint entity = entities[msg.sender];
        require (entity > 0, "Entity not registered!");
        sVariable storage v = variables[entity][keccak256(abi.encode(_name))];
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
    function get(sAddress memory self) public view returns (address _address){
        bytes memory _data = get(self.variable.name, DATATYPE.ADDRESS);
        (_address) = abi.decode(_data, (address));
        return _address;
    }
    function get(sBoolean memory self) public view returns (bool _bool){
        bytes memory _data = get(self.variable.name, DATATYPE.BOOLEAN);
        (_bool) = abi.decode(_data, (bool));
        return _bool;
    }

    function get(sInteger memory self) public view returns (int _int){
        bytes memory _data = get(self.variable.name, DATATYPE.INTEGER);
        (_int) = abi.decode(_data, (int));
        return _int;
    }
    function get(sString memory self) public view returns (string memory _string){
        bytes memory _data = get(self.variable.name, DATATYPE.STRING);
        (_string) = abi.decode(_data, (string));
        return _string;
    }
    
    function stringToBytes32(string memory self) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(self);
        require(tempEmptyStringTest.length <= 32, "Variable name can not exceed 32 bytes.");
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(self, 32))
        }
    }
    function bytes32ToString(bytes32 self) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = self[i];
            }
        return string(bytesArray);
    }

    function substring(bytes memory self, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = self[i];
        }
        return result;
    }
}
