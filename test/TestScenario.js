/*const BigNumber = require('bignumber.js');

function dec2hex(str) { // .toString(16) only works up to 2^53
    var dec = str.toString().split(''), sum = [], hex = [], i, s
    while(dec.length){
        s = 1 * dec.shift()
        for(i = 0; s || i < sum.length; i++){
            s += (sum[i] || 0) * 10
            sum[i] = s % 16
            s = (s - sum[i]) / 16
        }
    }
    while(sum.length){
        hex.push(sum.pop().toString(16))
    }
    return hex.join('')
}*/

const BatteryOwnershipService = artifacts.require("BatteryOwnershipService");
const BatteryPaymentToken = artifacts.require("BatteryPaymentToken");

contract('Battery Ownership Transfer Test', (accounts) => {

  const manager = accounts[0];
  const purchaser = accounts[1];
  const seller = accounts[2];

  const initialBPTSupply = 1000000000;
  const batteryPrice = 1000;

  //const batteryId = 1001;
  //const certificateId = 3001;
  const batteryId = '0x737af5c05e1042a7a7cb985c72d8c652'; // 153499664163277920257830542901849409106
  const certificateId = '0x23fe757ca7a4446da14d0cd366aa73d9'; // 47844206172638264401317781752603374553

  const batteryModelName = "EBM123";
  const batteryManufacterer = "SK Inovation";
  const batteryProductionDate = "2020-11-11";

  const certificateHash = "0x9cb50d33cd793f6a3d83e5474f0f1e0081813f626bcb3682d7cce2eeff07962c";
  const certificategrade = "AA+";
	const certificateEvaluationDate = "2020-11-13";
	const certificateEvaluationInstitute = "KIBE";

  it('should create battery ownership(NFT) of seller', async () => {
    console.log("------------------------------------------------------------------------------");
    const batteryOwnershipServiceInstance = await BatteryOwnershipService.deployed();
    
    // issue BatteryOwnershipToken(BOT) and create battery ownership for seller
    console.log("-> initializing Battery Ownership Token(BOT) and creating battery ownership for seller...");

    await batteryOwnershipServiceInstance.methods['initialize(string,string)']("Battery Ownership Token", "BOT", { from: manager });
    await batteryOwnershipServiceInstance.createOwnership(batteryId, seller, batteryModelName, batteryManufacterer, batteryProductionDate, { from: manager });

    const ownerOfBattery = await batteryOwnershipServiceInstance.ownerOf.call(batteryId);
    console.log("Battery Owner Address : " + ownerOfBattery);

    const batteryInfo = await batteryOwnershipServiceInstance.getBatteryInfo.call(batteryId);
    console.log("Battery Model Name : " + batteryInfo.modelName);

    assert.equal(ownerOfBattery, seller, "Owner of battery is not seller");
    assert.equal(batteryInfo.modelName, batteryModelName, "Battery information wasn't correctly saved .");
  });

  it('should assign BPT coin to buyer', async () => {
    console.log("------------------------------------------------------------------------------");
    const batteryPaymentTokenInstance = await BatteryPaymentToken.deployed();

    // issue Battery Payment Token(BPT)
    console.log("-> initializing Battery Payment Token(BPT) ...");
    
    await batteryPaymentTokenInstance.methods['initialize(string,string,uint256,address)']("Battery Payment Token", "BPT", initialBPTSupply, manager, { from: manager });

    const totalSupplyBPT = await batteryPaymentTokenInstance.totalSupply.call();
    console.log("BPT Total Supply : " + totalSupplyBPT.toNumber());

    // send coin to purchaser
    console.log("-> assigning 1000 BPT to purchaser ...");
    
    await batteryPaymentTokenInstance.transfer(purchaser, batteryPrice, { from: manager });

    const purchaserBalance = await batteryPaymentTokenInstance.balanceOf.call(purchaser);
    console.log("Purchaser Balance : " + purchaserBalance.toNumber());
    
    assert.equal(purchaserBalance.toNumber(), batteryPrice, "1000 BPT wasn't correctly assigned to purchaser.");
  });

  it('should save battery certificate with hash for seller', async () => {
    console.log("------------------------------------------------------------------------------");
    const batteryOwnershipServiceInstance = await BatteryOwnershipService.deployed();
  
    // save battery certificate information and hash for seller
    console.log("-> saving battery certificate information and hash for seller...");

    await batteryOwnershipServiceInstance.saveCertificateHash(batteryId, certificateHash, certificateId, 
                  certificategrade, certificateEvaluationDate, certificateEvaluationInstitute, { from: manager });

    const certificateInfo = await batteryOwnershipServiceInstance.getCertificateInfo.call(batteryId, certificateId);
    console.log("<Certificate Info>");
    console.log("Certificate ID : " + certificateInfo.certificateId);
    console.log("Certificate Hash : " + certificateInfo.certificateHash);

    const batteryInfo = await batteryOwnershipServiceInstance.getBatteryInfo.call(batteryId);
    console.log("<Battery Info>");
    console.log("Battery ID : " + batteryInfo.batteryId);
    console.log("Current Certificate ID : " + batteryInfo.currentCertificateId);
    console.log("Current Certificate Hash : " + batteryInfo.currentCertificateHash);

    /*console.log(typeof(certificateInfo.certificateId));
    console.log(certificateInfo.certificateId);
    certificateIdBN = new BigNumber(batteryInfo.currentCertificateId);
    certificateIdStr = certificateIdBN.toString().substr(0, certificateIdBN.toString().length - 4).replace('.', '');
    console.log(dec2hex(certificateIdStr));
    certificateIdStr2 = '';
    for (i = 0; i < certificateIdBN.c.length;i++) {
      certificateIdStr2 += certificateIdBN.c[i];
    }
    console.log(certificateIdStr2);
    console.log(dec2hex(certificateIdStr2));*/
    //assert.equal(certificateInfo.certificateId.toNumber(), Number(certificateId), "Certificate information wasn't correctly saved .");
    
    assert.equal(certificateInfo.certificateHash, certificateHash, "Certificate information wasn't correctly saved .");
  });

  it('should validate battery certificate by hash', async () => {
    console.log("------------------------------------------------------------------------------");
    const batteryOwnershipServiceInstance = await BatteryOwnershipService.deployed();
    
    // validate battery certificate hash
    console.log("-> validating battery certificate hash of seller with certificate hash generated by purchaser...");

    const isValid = await batteryOwnershipServiceInstance.validateCertificateHash.call(batteryId, certificateHash, { from: purchaser });
    console.log("Validation Result : " + isValid);

    assert.equal(isValid, true, "Certificate hash wasn't correct.");
  });

  it('should send BPT to seller', async () => {   
    console.log("------------------------------------------------------------------------------");
    const batteryPaymentTokenInstance = await BatteryPaymentToken.deployed();

    // send coin to seller
    console.log("-> sending 1000 BPT to seller ...");

    const sellerPrevBalance = (await batteryPaymentTokenInstance.balanceOf.call(seller)).toNumber();
    const purchaserPrevBalance = (await batteryPaymentTokenInstance.balanceOf.call(purchaser)).toNumber();
    
    await batteryPaymentTokenInstance.transfer(seller, batteryPrice, { from: purchaser });

    const sellerCurrBalance = (await batteryPaymentTokenInstance.balanceOf.call(seller)).toNumber();
    const purchaserCurrBalance = (await batteryPaymentTokenInstance.balanceOf.call(purchaser)).toNumber();

    console.log("Seller Balance : " + sellerCurrBalance);
    console.log("Purchaser Balance : " + purchaserCurrBalance);

    assert.equal(sellerCurrBalance, sellerPrevBalance + batteryPrice, "1000 BPT wasn't correctly sent to seller.");
    assert.equal(purchaserCurrBalance, purchaserPrevBalance - batteryPrice, "1000 BPT wasn't correctly taken from purchaser.");
  });  

  it('should transfer battery ownership to purchaser', async () => {
    console.log("------------------------------------------------------------------------------");
    const batteryOwnershipServiceInstance = await BatteryOwnershipService.deployed();
    
    // transfer battery ownership to purchaser
    console.log("-> transfering battery ownership to purchaser...");    
    
    await batteryOwnershipServiceInstance.transferFrom(seller, purchaser, batteryId, { from: seller });

    const ownerOfBattery = await batteryOwnershipServiceInstance.ownerOf.call(batteryId);
    console.log("Battery Owner Address : " + ownerOfBattery);

    assert.equal(ownerOfBattery, purchaser, "Owner of battery is not purchaser");
  });
});
