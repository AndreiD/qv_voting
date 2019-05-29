pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract QVVoting {
    using SafeMath for uint256;

    event voteCasted(address voter, uint ProposalID, bool vote, uint weight);
    event ProposalCreated(
        address creator,
        uint ProposalID,
        string description,
        uint votingTimeInHours
    );
    event ProposalStatusUpdate(bool status);

    enum ProposalStatus {IN_PROGRESS, TALLY}

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
        bool vote;
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

    function createProposal(
        string calldata _description,
        uint _voteExpirationTime
    ) external returns (uint) {
        require(_voteExpirationTime > 0, "the voting period cannot be 0");
        ProposalCount++;

        Proposal storage curProposal = Proposals[ProposalCount];
        curProposal.creator = msg.sender;
        curProposal.status = ProposalStatus.IN_PROGRESS;
        curProposal.expirationTime = now + 60 * 60 * _voteExpirationTime * 1 seconds;
        curProposal.description = _description;

        emit ProposalCreated(
            msg.sender,
            ProposalCount,
            _description,
            _voteExpirationTime
        );
        return ProposalCount;
    }

    function endProposal(uint _ProposalID) external validProposal(_ProposalID) {
        require(
            msg.sender == Proposals[_ProposalID].creator,
            "voter is not the creator of the Proposal"
        );
        require(
            Proposals[_ProposalID].status == ProposalStatus.IN_PROGRESS,
            "Vote is not in progress"
        );
        require(
            now >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.TALLY;
    }

    function getProposalStatus(uint _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (ProposalStatus)
    {
        return Proposals[_ProposalID].status;
    }

    function getProposalExpirationTime(uint _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (uint)
    {
        return Proposals[_ProposalID].expirationTime;
    }

    function getProposalHistory(address _voter)
        public
        view
        returns (uint[] memory)
    {
        return bank[_voter].participatedProposals;
    }

    modifier validProposal(uint _ProposalID) {
        require(
            _ProposalID > 0 && _ProposalID <= ProposalCount,
            "Not a valid Proposal Id"
        );
        _;
    }

    function getVotersForProposal(uint _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (address[] memory)
    {
        require(getProposalStatus(_ProposalID) != ProposalStatus.IN_PROGRESS);
        return Proposals[_ProposalID].voters;
    }

    function countVotes(
        uint _ProposalID,
        uint[] memory _votes,
        uint[] memory _weights
    ) public pure returns (uint, uint, uint) {
        require(_votes.length == _weights.length);
        uint yesVotes;
        uint noVotes;
        for (uint i = 0; i < _votes.length; i++) {
            if (_votes[i] == 0) noVotes += _weights[i];
            else if (_votes[i] == 1) yesVotes += _weights[i];
        }
        return (_ProposalID, yesVotes, noVotes);
    }

    function voterHasVoted(uint _ProposalID, address _voter)
        public
        view
        validProposal(_ProposalID)
        returns (bool)
    {
        return (Proposals[_ProposalID].voterInfo[_voter].hasVoted);
    }

    function getTokenSubmitted(address _voter) public view returns (uint) {
        return bank[_voter].tokenBalance;
    }

    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /*
   * Gets the status of a proposal.
   */
    function getproposalStatus(uint _proposalID)
        public
        view
        validProposal(_proposalID)
        returns (ProposalStatus)
    {
        return Proposals[_proposalID].status;
    }

    /*
   * Gets the expiration date of a proposal.
   */
    function getproposalExpirationTime(uint _proposalID)
        public
        view
        validProposal(_proposalID)
        returns (uint)
    {
        return Proposals[_proposalID].expirationTime;
    }

    function getVotersForproposal(uint _proposalID)
        public
        view
        validProposal(_proposalID)
        returns (address[] memory)
    {
        require(getproposalStatus(_proposalID) != ProposalStatus.IN_PROGRESS);
        return Proposals[_proposalID].voters;
    }

    /*
   * Casts a vote for a given proposal.
   */
    function castVote(uint _proposalID, uint numTokens, bool one_or_zero)
        external
        validProposal(_proposalID)
    {
        require(
            getproposalStatus(_proposalID) == ProposalStatus.IN_PROGRESS,
            "proposal has expired."
        );
        require(
            !userHasVoted(_proposalID, msg.sender),
            "User has already voted."
        );
        require(getproposalExpirationTime(_proposalID) > now);

        uint256 weight = sqrt(numTokens); // QV Vote
        // update token bank
        bank[msg.sender].lockedTokens[_proposalID] = weight;
        bank[msg.sender].participatedProposals.push(_proposalID);

        Proposal storage curproposal = Proposals[_proposalID];

        curproposal.voterInfo[msg.sender] = Voter({
            hasVoted: true,
            vote: one_or_zero,
            weight: weight
        });

        curproposal.voters.push(msg.sender);

        emit voteCasted(msg.sender, _proposalID, one_or_zero, weight);
    }

    /*
   * Checks if a user has voted for a specific proposal.
   */
    function userHasVoted(uint _proposalID, address _user)
        public
        view
        validProposal(_proposalID)
        returns (bool)
    {
        return (Proposals[_proposalID].voterInfo[_user].hasVoted);
    }

    /*
   * Gets the amount of Voting Credits for a given voter.
   */
    function getTokenStake(address _voter) public view returns (uint) {
        return bank[_voter].tokenBalance;
    }

}
