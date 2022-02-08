let HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
    networks: {
      development: {
        host: "local-node",
        port: 8545,
        network_id: "*" // Match any network id
      },
      moonbase: {
        provider: function() {
            return new HDWalletProvider({
                privateKeys: [process.env.MOONBASE_PRIV_KEY],
                providerOrUrl: process.env.MOONBASE_NODE_URL,
                addressIndex: 0
            })
        },
        network_id: 1287
      },
      moonbeam: {
        provider: function() {
          return new HDWalletProvider({
            privateKeys: [process.env.MOONBEAM_PRIV_KEY],
            providerOrUrl: process.env.MOONBEAM_NODE_URL,
            addressIndex: 0
          })
        },
        network_id:1284
      }
      // rinkeby: {
      //   provider: function() {
      //     return new HDWalletProvider({
      //       privateKeys: [],
      //       providerOrUrl: "",
      //       addressIndex: 0
      //     })
      //   }
      // }
    },
    compilers: {
      solc: {
        version: "0.6.7"
      }
    }
  };