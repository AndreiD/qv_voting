var PrivateKeyProvider = require("truffle-privatekey-provider");
var rinkebyByPrivateKey = require("./config/secrets").rinkebyPrivateKey;
var rinkebyProvider = require("./config/secrets").rinekebyUrl;

module.exports = {
  networks: {
    dev: {
      host: 'localhost',
      port: 8545,
      network_id: "*",
      gas: 5500000,
      from: "0x95915d3457da59f25cfc6f53b7f2056b376943e4"
    },
    rinkeby: {
      provider: new PrivateKeyProvider(rinkebyByPrivateKey, rinkebyProvider),
      network_id: 4,
      gas: 4500000
    }
  }
};
