const PrivateKeyProvider = require("@truffle/hdwallet-provider");
 
//const privateKey = "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";
//const privateKeyProviderMainnet = new PrivateKeyProvider(privateKey, "https://besu.chainz.network");
//const privateKeyProviderTestnet = new PrivateKeyProvider(privateKey, "https://besutest.chainz.network");
const privateKeys = [ 
  "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
  "0x91E25358ABC90DC9A6C915D439A878CE6F581D05FBD0CCB5167E8D7DB621FF50",
  "0x719531D7DB4A385034873E69308565CE5D05E3DA524103E25EFDFC1889B1B335"
];

module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  compilers: {
    solc: {
      version: "^0.5.0",
      // settings: {
      //   optimizer: {
      //     enabled: true,
      //     runs: 1500
      //   }
      // }
    }
  },
  networks: {
   development: {
     host: "127.0.0.1",
     port: 7545,
     network_id: "5777"
   },
   testnet: {
     host: "https://besutest.chainz.network",
     port: 443,
     network_id: "*"
   },
   // mainnet
   besu: {
     //provider: privateKeyProviderMainnet,
     provider: () => new PrivateKeyProvider(privateKeys, "https://besu.chainz.network", 0, 3),
     gasPrice: 0,
     network_id: "2020"
   },
   // testnet
   besuTest: {
     //provider: privateKeyProviderTestnet,
     provider: () => new PrivateKeyProvider(privateKeys, "https://besutest.chainz.network", 0, 3),
     gasPrice: 0,
     network_id: "2020"
   }
  } 
};
