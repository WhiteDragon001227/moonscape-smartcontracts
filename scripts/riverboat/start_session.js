let Riverboat = artifacts.require("Riverboat");
let RiverboatNft = artifacts.require("RiverboatNft");
let Rib = artifacts.require("Rib");



let accounts;

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

    let riverboat = await Riverboat.at("0xbf7843E2CeD5dedB99da23185aaB25962E9e8645");
    let riverboatNft = await RiverboatNft.at("0x0FA0A690D71430f1A2DA08E82Ba50f18DCAd452a");
    let rib = await Rib.at("0x2B57fc3a6bD98Aba718FCCe5554170B1315Ad691");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let currencyAddress = rib.address;
    let nftAddress = riverboatNft.address;
    let lighthouseTierAddress = '0xeFfdB75Ff90349151E100D82Dfd38fa1d7f050D2';
    let startPrice = web3.utils.toWei("0.05", "ether");
    let priceIncrease = web3.utils.toWei("0.05", "ether");
    let startTime = 1638886200;
    let intervalDuration = 900;
    let intervalsAmount = 10;
    let slotsAmount = 5;



    // contract calls
    await startSession();

    // let receiver = "0xE71d14a3fA97292BDE885C1D134bE4698e09b3B7";
    // let transferAmount = web3.utils.toWei("783", "ether");
    // await rib.transfer(receiver, transferAmount, {from: owner});
    // console.log("rib was transfered");




    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // add currency address -only needs to run once per currency
    async function startSession(){
        console.log("attempting to start session...");
        await riverboat.startSession(currencyAddress, nftAddress, lighthouseTierAddress, startPrice,
          priceIncrease, startTime, intervalDuration, intervalsAmount, slotsAmount, {from: owner})
          .catch(console.error);

        let sessionId = parseInt(await riverboat.sessionId.call());
        console.log(`started session with id ${sessionId}`);
    }

}.bind(this);
