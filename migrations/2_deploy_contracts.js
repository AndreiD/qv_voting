const QVVoting = artifacts.require("../contracts/QVVoting.sol");

module.exports = function (deployer) {
  deployer.deploy(QVVoting);
};
