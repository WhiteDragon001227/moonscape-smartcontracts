let Defi        = artifacts.require("MoonscapeDefi");
let defiAddress = require('./defi-address');

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

    // contract calls
    let id = await defi.sessionId().catch(console.error);
    console.log(`Latest session id: ${id}`);
}.bind(this);
