//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

enum DATATYPE {BOOLEAN, BYTES, INTEGER, STRING, ADDRESS}
struct iVariable{
    bytes32 name;
    DATATYPE dataType; // 0 -> bytes, 1 -> integer, 2 -> string, 3 -> address
    bool isDeclared;
    bool isKey;
    bool isConstant;
    uint[] dataPointers;
}

library Library {
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
