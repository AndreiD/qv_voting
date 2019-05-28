pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./VoteToken.sol";

contract QVVoting {

  using SafeMath for uint256;

  event voteCasted(address voter, uint ProposalID, bytes vote, uint weight);
  event ProposalCreated(address creator, uint ProposalID, string description, uint votingTimeInHours);
  event ProposalStatusUpdate(bool status);

  enum ProposalStatus { IN_PROGRESS, TALLY }

  struct Proposal {
    address creator;
    ProposalStatus status;
    uint yesVotes;
    uint noVotes;
    string description;
    address[] voters;
    uint expirationTime;
    mapping(address => Voter) voterInfo;
  }

  struct Voter {
    bool hasVoted;
    bytes vote;
    uint weight;
  }

  struct TokenManager {
    uint tokenBalance;
    mapping(uint => uint) lockedTokens;
    uint[] participatedProposals;
  }

  mapping(uint => Proposal) public Proposals;
  mapping(address => TokenManager) public bank;
  uint public ProposalCount;
  VoteToken public token;

  constructor(address _vote_token_address) public {
    require(_vote_token_address != address(0), "please provide VoteTokenAddress");
    token = VoteToken(_vote_token_address);
  }

  function createProposal(string calldata  _description, uint _voteExpirationTime) external returns (uint){
    require(_voteExpirationTime > 0, "the voting period cannot be 0");
    ProposalCount++;

    Proposal storage curProposal = Proposals[ProposalCount];
    curProposal.creator = msg.sender;
    curProposal.status = ProposalStatus.IN_PROGRESS;
    curProposal.expirationTime = now + 60 * 60 * _voteExpirationTime * 1 seconds;
    curProposal.description = _description;

    emit ProposalCreated(msg.sender, ProposalCount, _description, _voteExpirationTime);
    return ProposalCount;
  }

  function endProposal(uint _ProposalID) external validProposal(_ProposalID) {
    require(msg.sender == Proposals[_ProposalID].creator, "voter is not the creator of the Proposal");
    require(Proposals[_ProposalID].status == ProposalStatus.IN_PROGRESS, "Vote is not in progress");
    require(now >= getProposalExpirationTime(_ProposalID), "voting period has not expired");
    Proposals[_ProposalID].status = ProposalStatus.TALLY;
  }


  function getProposalStatus(uint _ProposalID) public view validProposal(_ProposalID) returns (ProposalStatus) {
    return Proposals[_ProposalID].status;
  }


  function getProposalExpirationTime(uint _ProposalID) public view validProposal(_ProposalID) returns (uint) {
    return Proposals[_ProposalID].expirationTime;
  }


  function getProposalHistory(address _voter) public view returns(uint[] memory) {
    return bank[_voter].participatedProposals;
  }

  modifier validProposal(uint _ProposalID) {
    require(_ProposalID > 0 && _ProposalID <= ProposalCount, "Not a valid Proposal Id");
    _;
  }


  function getVotersForProposal(uint _ProposalID) public view validProposal(_ProposalID) returns (address[] memory) {
    require(getProposalStatus(_ProposalID) != ProposalStatus.IN_PROGRESS);
    return Proposals[_ProposalID].voters;
  }


  function castVote(uint _ProposalID, bytes calldata _encryptedVote, uint _weight) external validProposal(_ProposalID) {
    require(getProposalStatus(_ProposalID) == ProposalStatus.IN_PROGRESS, "proposal is expired");
    require(!voterHasVoted(_ProposalID, msg.sender), "voter has already voted");
    require(getProposalExpirationTime(_ProposalID) > now);
    require(getTokenSubmitted(msg.sender) >= _weight, "voter does not have enough staked tokens");

    // update token bank
    bank[msg.sender].lockedTokens[_ProposalID] = _weight;
    bank[msg.sender].participatedProposals.push(_ProposalID);

    Proposal storage curProposal = Proposals[_ProposalID];

    curProposal.voterInfo[msg.sender] = Voter({
        hasVoted: true,
        vote: _encryptedVote,
        weight: _weight
    });

    curProposal.voters.push(msg.sender);

    emit voteCasted(msg.sender, _ProposalID, _encryptedVote, _weight);
  }


  function countVotes(uint _ProposalID, uint[] memory _votes, uint[] memory _weights) public pure returns (uint, uint, uint) {
    require(_votes.length == _weights.length);
    uint yesVotes;
    uint noVotes;
    for (uint i = 0; i < _votes.length; i++) {
      if (_votes[i] == 0) noVotes += _weights[i];
      else if (_votes[i] == 1) yesVotes += _weights[i];
    }
    return (_ProposalID, yesVotes, noVotes);
  }


  function voterHasVoted(uint _ProposalID, address _voter) public view validProposal(_ProposalID) returns (bool) {
    return (Proposals[_ProposalID].voterInfo[_voter].hasVoted);
  }


  function getTokenSubmitted(address _voter) public view returns(uint) {
    return bank[_voter].tokenBalance;
  }

  function submitVotingTokens(uint _numTokens) external {
    require(token.balanceOf(msg.sender) >= _numTokens, "voter does not have enough tokens");
    require(token.transferFrom(msg.sender, address(this), _numTokens), "voter did not approve token transfer");


    bank[msg.sender].tokenBalance += sqrt(_numTokens); // QV
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}
}
