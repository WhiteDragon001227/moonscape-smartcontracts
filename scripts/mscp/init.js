let MscpVesting = artifacts.require("MscpVesting");

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

    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let investorAddress = "";
    let strategicInvestor = false;

    // contract calls
    await addInvestor();
    await disableInvestor();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    async function addInvestor(){
        console.log("attempting to add investor...");
        await mscpVesting.addInvestor(investorAddress, strategicInvestor, {from: owner})
          .catch(console.error);
        console.log(`${investorAddress} was added`);
        if(strategicInvestor)
          console.log("as strategic investor");
        else
          console.log("as private investor");
    }

    async function disableInvestor(){
      console.log("attempting to disable investor...");
      await mscpVesting.disableInvestor(investorAddress, {from: owner})
        .catch(console.error);
      console.log(`${investorAddress} was disabled`);
    }


}.bind(this);
