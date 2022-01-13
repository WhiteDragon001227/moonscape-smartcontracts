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

    let city = await City.at("0xffa086A32259be131b6a643D034512881A6B0f51");

    let owner = accounts[0];
    console.log(`Using account ${owner}`);
    console.log(`City ${city.address}`);


    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------
    let cityId = 1;
    let category = 1;

    // contract calls
    await mintCity(cityId, category, owner);

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    async function mintCity(cityId, category, to) {
        await city.mint(cityId, category, to, {from: owner}).catch(console.error);
        console.log(`${cityId} was minted for ${to}`);
    }
}.bind(this);
