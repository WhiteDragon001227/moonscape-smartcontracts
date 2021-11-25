var MscpToken = artifacts.require("./MscpToken.sol");
var MscpVesting = artifacts.require("./MscpVesting.sol");
var MscpPrivateVesting = artifacts.require("./MscpPrivateVesting.sol");



async function getAccount(id) {
    let accounts = await web3.eth.getAccounts();
    return accounts[id];
}


module.exports = async function(deployer, network) {

    if (network == "ganache") {
      let startTime = Math.floor(Date.now()/1000) + 5;
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      // await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
      //     console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      // });
      await deployer.deploy(MscpPrivateVesting, MscpToken.address, startTime).then(function(){
          console.log("MscpPrivateVesting contract was deployed at address: "+MscpPrivateVesting.address);
      });

    } else if (network == "rinkeby") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "";
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      // await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
      //     console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      // });

    } else if (network == "bsctestnet") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "";
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
          console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      });

    } else if (network == "moonbase") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D";
      // await deployer.deploy(MscpToken).then(function(){
      //     console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      // });
      await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
          console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      });

    } else if (network == "mainnet") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "";
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
          console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      });

    } else if (network == "bsc") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "";
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
          console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      });
    }
};
