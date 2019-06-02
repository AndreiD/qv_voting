pragma solidity >=0.4.25 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/access/roles/MinterRole.sol";

/**
 * @title QVVoting
 * @dev the manager for proposals / votes
 */
contract QVVoting is Ownable, MinterRole {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    string public symbol;
    string public name;
    mapping(address => uint256) private _balances;

    event VoteCasted(address voter, uint ProposalID, uint256 weight);

    event ProposalCreated(
        address creator,
        uint256 ProposalID,
        string description,
        uint votingTimeInHours
    );

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

    mapping(uint256 => Proposal) public Proposals;
    uint public ProposalCount;

    constructor() public {
        symbol = "QVV";
        name = "QV Voting";
    }

    /**
    * @dev Creates a new proposal.
    * @param _description the text of the proposal
    * @param _voteExpirationTime expiration time in minutes
    */
    function createProposal(
        string calldata _description,
        uint _voteExpirationTime
    ) external onlyOwner returns (uint) {
        require(_voteExpirationTime > 0, "The voting period cannot be 0");
        ProposalCount++;

        Proposal storage curProposal = Proposals[ProposalCount];
        curProposal.creator = msg.sender;
        curProposal.status = ProposalStatus.IN_PROGRESS;
        curProposal.expirationTime = now + 60 * _voteExpirationTime * 1 seconds;
        curProposal.description = _description;

        emit ProposalCreated(
            msg.sender,
            ProposalCount,
            _description,
            _voteExpirationTime
        );
        return ProposalCount;
    }

    /**
    * @dev sets a proposal to TALLY.
    * @param _ProposalID the proposal id
    */
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

    /**
    * @dev sets a proposal to ENDED.
    * @param _ProposalID the proposal id
    */
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

    /**
    * @dev returns the status of a proposal
    * @param _ProposalID the proposal id
    */
    function getProposalStatus(uint _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (ProposalStatus)
    {
        return Proposals[_ProposalID].status;
    }

    /**
    * @dev returns a proposal expiration time
    * @param _ProposalID the proposal id
    */
    function getProposalExpirationTime(uint _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (uint)
    {
        return Proposals[_ProposalID].expirationTime;
    }

    /**
    * @dev counts the votes for a proposal. Returns (yeays, nays)
    * @param _ProposalID the proposal id
    */
    function countVotes(uint256 _ProposalID) public view returns (uint, uint) {
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

        return (yesVotes, noVotes);

    }

    /**
    * @dev casts a vote.
    * @param _ProposalID the proposal id
    * @param numTokens number of voice credits
    * @param _vote true for yes, false for no
    */
    function castVote(uint _ProposalID, uint numTokens, bool _vote)
        external
        validProposal(_ProposalID)
    {
        require(
            getProposalStatus(_ProposalID) == ProposalStatus.IN_PROGRESS,
            "proposal has expired."
        );
        require(
            !userHasVoted(_ProposalID, msg.sender),
            "user already voted on this proposal"
        );
        require(
            getProposalExpirationTime(_ProposalID) > now,
            "for this proposal, the voting time expired"
        );

        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);

        uint256 weight = sqrt(numTokens); // QV Vote

        Proposal storage curproposal = Proposals[_ProposalID];

        curproposal.voterInfo[msg.sender] = Voter({
            hasVoted: true,
            vote: _vote,
            weight: weight
        });

        curproposal.voters.push(msg.sender);

        emit VoteCasted(msg.sender, _ProposalID, weight);
    }

    /**
    * @dev checks if a user has voted
    * @param _ProposalID the proposal id
    * @param _user the address of a voter
    */
    function userHasVoted(uint _ProposalID, address _user)
        internal
        view
        validProposal(_ProposalID)
        returns (bool)
    {
        return (Proposals[_ProposalID].voterInfo[_user].hasVoted);
    }

    /**
    * @dev checks if a proposal id is valid
    * @param _ProposalID the proposal id
    */
    modifier validProposal(uint _ProposalID) {
        require(
            _ProposalID > 0 && _ProposalID <= ProposalCount,
            "Not a valid Proposal Id"
        );
        _;
    }

    /**
    * @dev returns the square root (in int) of a number
    * @param x the number (int)
    */
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
    * @dev minting more tokens for an account
    */
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), " mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    /**
    * @dev returns the balance of an account
    */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

}
