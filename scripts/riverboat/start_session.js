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

    let riverboat = await Riverboat.at("0x5434BDc9de2005278532F9041cBf3C939E48C4DC");
    let riverboatNft     = await RiverboatNft.at("0x115Aa9E35564307365Ca3f215f67eB69886f2fD1");
    let rib = await Rib.at("0x55512B86d04E40d7CcE82736c8051e292c4ED31B");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let currencyAddress = rib.address;
    let nftAddress = riverboatNft.address;
    let lighthouseTierAddress = '0x0000000000000000000000000000000000000000';
    let startPrice = web3.utils.toWei("1", "ether");
    let priceIncrease = web3.utils.toWei("1", "ether");
    let startTime = Math.floor(Date.now()/1000) + 60;
    let intervalDuration = 10800;
    let intervalsAmount = 8;
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
          priceIncrease, startTime, intervalDuration, intervalsAmount, slotsAmount, {from: owner})
          .catch(console.error);

        let sessionId = parseInt(await riverboat.sessionId.call());
        console.log(`started session with id ${sessionId}`);
    }

}.bind(this);
