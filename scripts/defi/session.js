let Defi        = artifacts.require("MoonscapeDefi");
let defiAddress = require('./defi-address');

// global variables
let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {
    let address = defiAddress.ofSession(networkId);

    let defi = await Defi.at(address).catch(e => {
        console.error(e);
        process.exit(1);
    });

    accounts = await web3.eth.getAccounts();

    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------
    let startTime = Math.floor(new Date().getTime() / 1000) + 300;
    let endTime = startTime + 3600 * 24;

    // contract calls
    await defi.startSession(startTime, endTime, {from: owner}).catch(console.error);
    console.log(`New session was started. Now start to add token stakings.`);
}.bind(this);
