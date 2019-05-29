pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/access/roles/MinterRole.sol";
import "./QVVoting.sol";

// Like an ERC20 Token, but not transferable
contract VoteToken is Ownable, MinterRole {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint tokens);

    uint256 private _totalSupply;
    string public symbol;
    string public name;

    QVVoting qv_contract;

    mapping(address => uint256) private _balances;

    constructor(address _voting_contract) public {
        symbol = "VOTE";
        name = "Voting Token";
        qv_contract = QVVoting(_voting_contract);
        _mint(msg.sender, 1000000000000000); // adds some starting tokens
    }

    // amount is the voice credits, vote is true: yes, false: no
    function castVote(uint256 proposal_id, uint256 amount, bool vote)
        public
        returns (bool)
    {
        require(
            msg.sender != address(0),
            "VotingToken: transfer from the zero address"
        );
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        qv_contract.castVote(proposal_id, amount, vote);
        //emit Voted
        return true;
    }

    // used to mint more voting tokens by the owner
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getVotingContractAddress() public view returns (address) {
        return address(qv_contract);
    }
}
