const BMSContract = artifacts.require("BMSContract");
const DocumentService = artifacts.require("DocumentService");


module.exports = function(deployer) {
  deployer.deploy(BMSERC20);
  deployer.deploy(DocumentService);
};
