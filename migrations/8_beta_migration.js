var Beta = artifacts.require("./MoonscapeBeta.sol");

module.exports = async function(deployer, network) {
    let accounts = await web3.eth.getAccounts();
    console.log(`using ${accounts[0]}`);

    if (network != "moonbase") {
        throw `'${network}' network is not supported`;
    }

    let token = "0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D";
    let startTime = Math.floor(new Date().getTime() / 1000) + 100;
    let endTime = startTime + (3600 * 24 * 7);  // 1 week session

    console.log(`Staking Token ${token} between ${new Date(startTime * 1000)} and ${new Date(endTime * 1000)}`);

    await deployer.deploy(Beta, token, startTime, endTime);

    console.log(`Staking contract was deployed on ${Beta.address}`);
};
