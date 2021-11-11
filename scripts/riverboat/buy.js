let Riverboat = artifacts.require("Riverboat");
let RiverboatNft = artifacts.require("RiverboatNft");


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

    let riverboat = await Riverboat.at("0x8E61f5028eEA48fdd58FD3809fc2202ABdBDC126");
    let riverboatNft     = await RiverboatNft.at("0x7115ABcCa5f0702E177f172C1c14b3F686d6A63a");


    let player = accounts[0];
    console.log(`Using account ${player}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let sessionId = parseInt(await riverboat.lastSessionId.call());
    sessionId = console.log(`last session id: ${sessionId}`);
    let nftId = await riverboatNft.tokenOfOwnerByIndex(riverboat.address, index);

    // contract calls
    await buy();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // add currency address -only needs to run once per currency
    async function buy(){
        console.log(`attempting to buy nft...`);
        await riverboat.buy(sessionId, nftId, {from: player})
          .catch(console.error);
        console.log(`bought nft id${nftId}`);
    }


}.bind(this);
