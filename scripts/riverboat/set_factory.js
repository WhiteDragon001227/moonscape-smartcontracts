let Riverboat = artifacts.require("Riverboat");
let Nft = artifacts.require("RiverboatNft");
let Factory = artifacts.require("RiverboatFactory");


let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {
    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    // contracts
    let factory  = await Factory.at("0x2B57fc3a6bD98Aba718FCCe5554170B1315Ad691");
    let nft     = await Nft.at("0x0FA0A690D71430f1A2DA08E82Ba50f18DCAd452a");

    // global variables
    let user = accounts[0];
    console.log(`Using ${user}`);

    /// call this first
    // console.log("attempting to set factory...");
    // await nft.setFactory(factory.address, {from: user}).catch(console.error);
    // console.log("factory was set");

    /// call this second
    console.log("attempting to set nft...")
    await factory.setNft(nft.address, {from: user}).catch(console.error);
    console.log("nft was set");
    console.log("checking if user is generator?");
    let isGiven = false;
    try{
      isGiven = await factory.isGenerator(user);
    }catch(err){
      console.log(err);
    };
    console.log(isGiven);
    if (!isGiven) {
    console.log("attemping to add generator...");
    await factory.addGenerator(user).catch(console.error);
    console.log("user is generator");
    }

}.bind(this);
