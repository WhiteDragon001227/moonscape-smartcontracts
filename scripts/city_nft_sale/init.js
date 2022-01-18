let CityNftSale = artifacts.require("CityNftSale");

// global variables
let accounts;
let multiplier = 1000000000000000000;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {

    //--------------------------------------------------
    // Accounts and contracts configuration
    //--------------------------------------------------

    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let cityNftSale = await CityNftSale.at("0xd2F438FdA5b95F3bdc3512aaC30526AeB2202455");

    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    // global vars
    let tradeEnabled = true;
    let priceReceiver = owner;
    let verifier = owner;

    // contract calls
    // await enableTrade();
    // await setPriceReceiver();
    //await setVerifier();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // add currency address -only needs to run once per currency
    async function setPriceReceiver(){
        console.log("attempting to set price receiver...");
        await cityNftSale.setPriceReceiver(priceReceiver, {from: owner})
          .catch(console.error);
        console.log(`${currencyAddress} was set as price receiver`);
    }

    // enable trade (true/false) -only needs to run once
    async function enableTrade(){
      console.log("attempting to enable trade...");
      await cityNftSale.enableTrade(tradeEnabled, {from: owner});
      console.log(`tradeEnabled was set to ${tradeEnabled}`);
    }

    async function setVerifier(){
      console.log("attempting to set verifier...");
      await cityNftSale.setVerifier(verifier, {from: owner});
      console.log(`verifier was set to ${verifier}`);
    }


}.bind(this);
