let Defi        = artifacts.require("MoonscapeDefi");
let Token       = artifacts.require("Rib");
let defiAddress = require('./defi-address');

// global variables
let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {
    let address = defiAddress.ofSession(networkId);

    let defi = await Defi.at(address).catch(e => {
        console.error(e);
        process.exit(1);
    });

    let tokenAddress = defiAddress.ofCrowns(networkId);
    let tokenAddress1 = '0x98b154eba8ed233697491145d5ddbd19dfda130e';

    let token1 = await Token.at(tokenAddress).catch(e => {
        console.error(e);
        process.exit(1);
    });

    let token2 = await Token.at(tokenAddress1).catch(e => {
        console.error(e);
        process.exit(1);
    })

    accounts = await web3.eth.getAccounts();

    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------
    let sessionId = 2;

    // contract calls
    // addTokenStaking(uint _sessionId, address stakeAddress, uint rewardPool, address rewardToken)
    await defi.addTokenStaking(sessionId, tokenAddress, web3.utils.toWei('100'), tokenAddress).catch(console.error);
    console.log(`Added staking with ${tokenAddress} and rewarding with ${tokenAddress}.`);
    await defi.addTokenStaking(sessionId, tokenAddress1, web3.utils.toWei('100'), tokenAddress).catch(console.error);
    console.log(`Added staking with ${tokenAddress1} and rewarding with ${tokenAddress}.`);

}.bind(this);
