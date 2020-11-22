require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');


/**
 * You can use Ganache.app for Local Blockcahin
 * It will work for me @sayedsoft 
 * My name is : Ahmad yaman sayed 
 * Email : yemen@alitasoft.com.tr
 * Turkiye/Mersin
 */

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    ropsten: { 
      provider : function () {
          return new HDWalletProvider(
            process.env.MNEMONIC,
            //'https://mainnet.infura.io/v3/'+process.env.INFURA_API_KEY
            'https://ropsten.infura.io/v3/'+process.env.INFURA_API_KEY
          );
      },
      network_id: 3,       // Ropsten's id
      gas: 7000000, 
  },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
        version:"0.6.12",
        settings: { 
          optimizer: {
          enabled: false,
          runs: 200
        },
      }
    },
  }

};
