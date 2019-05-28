pragma solidity >=0.4.25 <0.6.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract Management is Ownable {

    using SafeMath for uint256;


    string defaultName;
    constructor() public {
        defaultName = "World";
    }
    function getMessage() public view returns (string memory) {
        return defaultName;
    }
}
