pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

// a simple ERC20 token with 0 decimals
contract VoteToken is ERC20Mintable {
  string public name = "Votes";
  string public symbol = "VOTE";
  uint256 public decimals = 0;

  constructor() public {
    mint(msg.sender, 100000000000000);
  }

}
