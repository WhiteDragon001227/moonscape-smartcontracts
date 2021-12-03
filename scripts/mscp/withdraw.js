let MscpVesting = artifacts.require("MscpVesting");
var MscpToken = artifacts.require("./MscpToken.sol");

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

    let mscpVesting = await MscpVesting.at("");
    var mscpToken = await MscpToken.at("");

    let user = accounts[0];
    console.log(`Using account ${user}`);

    let oldBalance = parseInt(await mscpToken.balanceOf(user))/multiplier;
    console.log("old balance: " ,oldBalance);

    console.log("attempting to add withdraw...");
    await mscpVesting.withdraw({from: privateInvestor})
      .catch(console.error);
    console.log(`${investorAddress} was added`);

    let newBalance = parseInt(await mscpToken.balanceOf(user))/multiplier;
    console.log("new balance: " ,newBalance);
    let difference = newBalance - oldBalance;
    if(difference != 0)
      console.log(`${user} has withdrawn ${difference} tokens`);


}.bind(this);
