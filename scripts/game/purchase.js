let Mscp = artifacts.require("MscpToken");
let Game = artifacts.require("MoonscapeGame");

// global variables
let accounts;
let multiplier = 1000000000000000000;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function() {

    //--------------------------------------------------
    // Accounts and contracts configuration
    //--------------------------------------------------

    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let mscp = await Mscp.at("0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D");
    let game = await Game.at("0x187574887e757Cb86276c36dcB51082C723A67F6");

    let owner = accounts[0];
    console.log(`Using account ${owner}`);
    console.log(`Game contract: ${game.address}, MSCP: ${mscp.address}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let amount          = "10";
    let amountWei       = web3.utils.toWei(amount);
    console.log(`Purchasing Moondust worth ${amount} MSCP.`);

    // contract calls
    await approve(amountWei);
    await purchase(amountWei);

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    async function approve(amountWei) {
        console.log("attempting to approve MSCP for Game...");
        await mscp.approve(game.address, amountWei, {from: owner}).catch(console.error);
        console.log(`${game.address} approved to spend MSCP tokens`);
    }

    async function purchase(amountWei) {
      console.log("attempting to purchase moondust...");
      await game.purchaseMoondust(amountWei, {from: owner}).catch(console.error);
      console.log(`${owner} purchased moondust`);
    }
}.bind(this);
