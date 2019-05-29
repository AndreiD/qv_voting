pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract QVVoting is Ownable {
    using SafeMath for uint256;

    event voteCasted(address voter, uint ProposalID, bool vote, uint256 weight);
    event ProposalCreated(
        address creator,
        uint256 ProposalID,
        string description,
        uint votingTimeInHours
    );
    event ProposalStatusUpdate(bool status);

    enum ProposalStatus {IN_PROGRESS, TALLY, ENDED}

    struct Proposal {
        address creator;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        string description;
        address[] voters;
        uint expirationTime;
        mapping(address => Voter) voterInfo;
    }

    struct Voter {
        bool hasVoted;
        bool vote;
        uint256 weight;
    }

    struct TokenManager {
        uint256 tokenBalance;
        mapping(uint256 => uint256) lockedTokens;
        uint256[] participatedProposals;
    }

    mapping(uint256 => Proposal) public Proposals;
    mapping(address => TokenManager) public bank;
    uint public ProposalCount;

    function createProposal(
        string calldata _description,
        uint _voteExpirationTime
    ) external returns (uint) {
        require(_voteExpirationTime > 0, "The voting period cannot be 0");
        ProposalCount++;

        Proposal storage curProposal = Proposals[ProposalCount];
        curProposal.creator = msg.sender;
        curProposal.status = ProposalStatus.IN_PROGRESS;
        curProposal.expirationTime = now + 60 * _voteExpirationTime * 1 seconds; // in minutes
        curProposal.description = _description;

        emit ProposalCreated(
            msg.sender,
            ProposalCount,
            _description,
            _voteExpirationTime
        );
        return ProposalCount;
    }

    function setProposalToTally(uint _ProposalID)
        external
        validProposal(_ProposalID)
        onlyOwner
    {
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

    function setProposalToEnded(uint _ProposalID)
        external
        validProposal(_ProposalID)
        onlyOwner
    {
        require(
            Proposals[_ProposalID].status == ProposalStatus.TALLY,
            "Proposal should be in tally"
        );
        require(
            now >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.ENDED;
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

    function countVotes(uint256 _ProposalID)
        public
        view
        returns (uint, uint, uint)
    {
        uint yesVotes = 0;
        uint noVotes = 0;

        address[] memory voters = Proposals[_ProposalID].voters;
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            bool vote = Proposals[_ProposalID].voterInfo[voter].vote;
            uint256 weight = Proposals[_ProposalID].voterInfo[voter].weight;
            if (vote == true) {
                yesVotes += weight;
            } else {
                noVotes += weight;
            }
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

    function getVotersForproposal(uint _proposalID)
        public
        view
        validProposal(_proposalID)
        returns (address[] memory)
    {
        require(getProposalStatus(_proposalID) != ProposalStatus.IN_PROGRESS);
        return Proposals[_proposalID].voters;
    }

    /*
   * Casts a vote for a given proposal.
   */
    function castVote(uint _proposalID, uint numTokens, bool _vote)
        external
        validProposal(_proposalID)
    {
        require(
            getProposalStatus(_proposalID) == ProposalStatus.IN_PROGRESS,
            "proposal has expired."
        );
        require(
            !userHasVoted(_proposalID, msg.sender),
            "User has already voted."
        );
        require(getProposalExpirationTime(_proposalID) > now);

        uint256 weight = sqrt(numTokens); // QV Vote
        // update token bank
        bank[msg.sender].lockedTokens[_proposalID] = weight;
        bank[msg.sender].participatedProposals.push(_proposalID);

        Proposal storage curproposal = Proposals[_proposalID];

        curproposal.voterInfo[msg.sender] = Voter({
            hasVoted: true,
            vote: _vote,
            weight: weight
        });

        curproposal.voters.push(msg.sender);

        emit voteCasted(msg.sender, _proposalID, _vote, weight);
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

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
