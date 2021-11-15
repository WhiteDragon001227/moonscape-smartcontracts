let Riverboat = artifacts.require("Riverboat");
let RiverboatNft = artifacts.require("RiverboatNft");
let Rib = artifacts.require("Rib");

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
    let multiplier = 1000000000000000000;
    console.log(accounts);

    let riverboat = await Riverboat.at("0x5434BDc9de2005278532F9041cBf3C939E48C4DC");
    let riverboatNft     = await RiverboatNft.at("0x115Aa9E35564307365Ca3f215f67eB69886f2fD1");
    let rib = await Rib.at("0x55512B86d04E40d7CcE82736c8051e292c4ED31B");


    let player = accounts[4];
    console.log(`Using account ${player}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let sessionId = parseInt(await riverboat.sessionId.call());
    console.log(`last session id: ${sessionId}`);
    let nftId = await riverboatNft.tokenOfOwnerByIndex(riverboat.address, 0);
    let amountToApprove = web3.utils.toWei("30", "ether");


    // contract calls
    await approveRib();
    await buy();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // approve crowns and check allowance
    async function approveRib(){
      console.log("attemping to approve Rib...");
      await rib.approve(riverboat.address, amountToApprove, {from: player});
      console.log("checking allowance");
      let allowance = (await rib.allowance(player, riverboat.address)).toString();
      console.log(`riverboat was approved to spend ${allowance/multiplier} Rib`);
    }

    // add currency address -only needs to run once per currency
    async function buy(){
        console.log(`attempting to buy nft...`);
        await riverboat.buy(sessionId, nftId, {from: player});
        console.log(`bought nft id${nftId}`);
    }


}.bind(this);
