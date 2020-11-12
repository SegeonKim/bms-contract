const Contract1 = artifacts.require("BatteryOwnershipService");
const Contract2 = artifacts.require("BatteryPaymentToken");


module.exports = function(deployer) {
  deployer.deploy(Contract1);
  deployer.deploy(Contract2);
};
