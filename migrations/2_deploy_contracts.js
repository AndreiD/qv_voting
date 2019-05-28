const JobEscrow = artifacts.require("../contracts/JobEscrow.sol");
const JobGenerator = artifacts.require("../contracts/JobGenerator.sol");


module.exports = function (deployer) {
  deployer.deploy(JobGenerator);
  deployer.deploy(JobEscrow);
};
