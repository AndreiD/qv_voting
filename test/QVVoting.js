

const QVVoting = artifacts.require("./QVVoting.sol");


contract('QVVoting Javascript Tests', async (accounts) => {

  let instance

  beforeEach('setup a new contract for each test', async function () {
    instance = await QVVoting.deployed()
  })

  it("owner starts with 0 tokens. can only mint", async () => {
    balance = await instance.balanceOf.call(accounts[0]);
    expect(Number(balance), "everyone starts with 0").to.equal(0);

    await instance.mint(accounts[1], 100, { from: accounts[0] })

    balance = await instance.balanceOf.call(accounts[1]);
    expect(Number(balance), "everyone starts with 0").to.equal(100);

  })

  it("creating a proposal works", async () => {
    balance = await instance.balanceOf.call(accounts[0]);
    expect(Number(balance), "everyone starts with 0").to.equal(0);

    await instance.createProposal("proposal description", 1, { from: accounts[0] })

    status = await instance.getProposalStatus.call(1);
    expect(Number(status), "status is 0").to.equal(0);

    expirationTime = await instance.getProposalExpirationTime.call(1);
    expect(Math.round(Number(expirationTime / 100)), "expirationTime is 0").to.equal(15592955);

  })

})
