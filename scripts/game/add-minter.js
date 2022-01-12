let Game = artifacts.require("MoonscapeGame");
let City = artifacts.require("CityNft");

// global variables
let accounts;

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

    let game = await Game.at("0x187574887e757Cb86276c36dcB51082C723A67F6");
    let city = await City.at("0xA2093C326b01c263f74435f26d8D2b2523BFA772");

    let owner = accounts[0];
    console.log(`Using account ${owner}`);
    console.log(`Game contract: ${game.address}, City ${city.address}`);


    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------
    // contract calls
    await setMinter(game.address);

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    async function setMinter(minter) {
        await city.setMinter(minter, {from: owner}).catch(console.error);
        console.log(`${minter} can mint city nfts`);
    }
}.bind(this);
