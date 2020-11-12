const PrivateKeyProvider = require("@truffle/hdwallet-provider");
 
const privateKey = "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";
//const privateKeyProviderMainnet = new PrivateKeyProvider(privateKey, "https://besu.chainz.network");
//const privateKeyProviderTestnet = new PrivateKeyProvider(privateKey, "https://besutest.chainz.network");

module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  compilers: {
    solc: {
      version: "^0.5.0"
    }
  },
  networks: {
   development: {
     host: "127.0.0.1",
     port: 8545,
     network_id: "*"
   },
   testnet: {
     host: "https://besutest.chainz.network",
     port: 443,
     network_id: "*"
   },
   // mainnet
   besu: {
    //provider: privateKeyProviderMainnet,
     provider: () => new PrivateKeyProvider(privateKey, "https://besu.chainz.network"),
     gasPrice: 0,
     network_id: "2020"
   },
   // testnet
   besuTest: {
     //provider: privateKeyProviderTestnet,
     provider: () => new PrivateKeyProvider(privateKey, "https://besutest.chainz.network"),
     network_id: "2020"
   }
  }
  
};
