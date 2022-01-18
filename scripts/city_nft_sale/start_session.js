let CityNftSale = artifacts.require("CityNftSale");
let CityNft = artifacts.require("CityNft");
let MscpToken = artifacts.require("MscpToken");



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

    let cityNftSale = await CityNftSale.at("0xd2F438FdA5b95F3bdc3512aaC30526AeB2202455");
    let cityNft = await CityNft.at("0x14C7C9D806c7fd8c1B45d466B910c6AbF6428F07");
    let mscpToken = await MscpToken.at("0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let currencyAddress = mscpToken.address;
    let nftAddress = cityNft.address;
    let lighthouseTierAddress = '0xeFfdB75Ff90349151E100D82Dfd38fa1d7f050D2';
    let startPrice = web3.utils.toWei("1", "ether");
    let priceIncrease = web3.utils.toWei("0.1", "ether");
    let startTime = 1642529220;
    let intervalDuration = 900;
    let intervalsAmount = 1;
    let tierRequirement = -1;


    // contract calls
    await startSession();

    // let receiver = "0xE71d14a3fA97292BDE885C1D134bE4698e09b3B7";
    // let transferAmount = web3.utils.toWei("783", "ether");
    // await mscpToken.transfer(receiver, transferAmount, {from: owner});
    // console.log("mscpToken was transfered");




    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // add currency address -only needs to run once per currency
    async function startSession(){
        console.log("attempting to start session...");
        await cityNftSale.startSession(currencyAddress, nftAddress, lighthouseTierAddress, startPrice,
          priceIncrease, startTime, intervalDuration, intervalsAmount, tierRequirement)
            .catch(console.error);

        let sessionId = parseInt(await cityNftSale.sessionId.call());
        console.log(`started session with id ${sessionId}`);
    }

}.bind(this);
