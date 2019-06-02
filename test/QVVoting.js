const QVVoting = artifacts.require("./QVVoting.sol");
const truffleAssert = require('truffle-assertions');

contract('QVVoting Javascript Tests', async (accounts) => {

  let instance

  beforeEach('setup a new contract for each test', async function () {
    instance = await QVVoting.deployed()
  })

  it("owner starts with 0 tokens. can only mint", async () => {
    balance = await instance.balanceOf.call(accounts[0]);
    expect(Number(balance), "everyone starts with 0").to.equal(0);

    await instance.mint(accounts[1], 100, {
      from: accounts[0]
    })

    balance = await instance.balanceOf.call(accounts[1]);
    expect(Number(balance), "everyone starts with 0").to.equal(100);

  })

  it("creating a proposal works", async () => {
    balance = await instance.balanceOf.call(accounts[0]);
    expect(Number(balance), "everyone starts with 0").to.equal(0);

    await instance.createProposal("proposal description", 1, {
      from: accounts[0]
    })

    status = await instance.getProposalStatus.call(1);
    expect(Number(status), "status is 0").to.equal(0);

    expirationTime = await instance.getProposalExpirationTime.call(1);
    var ts = Math.round((new Date()).getTime() / 1000);

    expect(Number(expirationTime) - ts, " diffrence is less than 1 second").to.be.within(59, 61);

  })


  it("a simple voting test", async () => {

    await instance.createProposal("proposal two", 1, {
      from: accounts[0]
    })

    status = await instance.getProposalStatus.call(2);
    expect(Number(status), "status is 0").to.equal(0);


    balanceAccount1 = await instance.balanceOf.call(accounts[1])
    expect(Number(balanceAccount1), "balance accounnt 1 is 100").to.equal(100);

    await instance.castVote(2, 16, true, {
      from: accounts[1]
    })

    balanceAccount1 = await instance.balanceOf.call(accounts[1])
    expect(Number(balanceAccount1), "balance accounnt 1 is 100-16").to.equal(84);


    var votes = await instance.countVotes.call(2)
    expect(Number(votes[0]), "yeys are 4").to.equal(4);
    expect(Number(votes[1]), "neys are 0").to.equal(0);

  })

  it("a user can't vote again", async () => {
    await truffleAssert.fails(instance.castVote(2, 16, true, {
      from: accounts[1]
    }), truffleAssert.ErrorType.REVERT);
  })

  it("a VoteCasted event is emited when voted", async () => {
    const tx = await instance.castVote(1, 8, true, {
      from: accounts[1]
    })
    truffleAssert.eventEmitted(tx, 'VoteCasted', (event) => {
      return (event.voter === accounts[1]);
    });
  })

  it("a user can't vote if it doesn't have enough credits", async () => {

    await instance.createProposal("proposal three", 1, {
      from: accounts[0]
    })

    balanceAccount1 = await instance.balanceOf.call(accounts[1])
    expect(Number(balanceAccount1), "balance accounnt 1 is 76").to.equal(76);


    await truffleAssert.fails(instance.castVote(2, 77, true, {
      from: accounts[1]
    }), truffleAssert.ErrorType.REVERT);
  })


})
