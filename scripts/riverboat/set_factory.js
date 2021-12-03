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
    let factory  = await Factory.at("0xF29af81595f575d88447C69B6a760862e6EB30eC");
    let nft     = await Nft.at("0x016f2b8fDF8F7c76b97a666fA31aBF064b1541B1");
    let riverboat = await Riverboat.at("0xfF6d9a52A37FccFa1dd5df767B68D39451E4b974");

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
    console.log("attemping to set the factory...");
    let isGiven = false;
    try{
      isGiven = await factory.isGenerator(user);
    }catch(err){
      console.log(err);
    };
    console.log(isGiven);
    if (!isGiven) {
    await factory.addGenerator(user).catch(console.error);
    console.log("factory was set");
    }

}.bind(this);
