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

    let riverboat = await Riverboat.at("0x8E61f5028eEA48fdd58FD3809fc2202ABdBDC126");
    let riverboatNft     = await RiverboatNft.at("0x7115ABcCa5f0702E177f172C1c14b3F686d6A63a");
    let rib = await Rib.at("");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let currencyAddress = rib.address;
    let nftAddress = riverboatNft.address;
    let lighthouseTierAddress = "0x0";
    let startPrice = web3.utils.toWei("1", "ether");
    let priceIncrease = web3.utils.toWei("1", "ether");
    let startTime = Math.floor(Date.now()/1000) + 60;
    let intervalDuration = 60;
    let intervalsAmount = 10;
    let slotsAmount = 3;



    // contract calls
    await startSession();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // add currency address -only needs to run once per currency
    async function startSession(){
        console.log("attempting to start session...");
        await riverboat.startSession(currencyAddress, nftAddress, lighthouseTierAddress, startPrice,
          priceIncrease, startTime, intervalDuration, intervalsAmount, slotsAmount {from: owner})
          .catch(console.error);

        let sessionId = parseInt(await riverboat.lastSessionId.call());
        console.log(`started session with id${sessionId}`);
    }

}.bind(this);
