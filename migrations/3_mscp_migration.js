var MscpToken = artifacts.require("./MscpToken.sol");
var MscpVesting = artifacts.require("./MscpVesting.sol");
var MscpVesting5M = artifacts.require("./MscpVesting5M.sol");
var MscpVesting30M = artifacts.require("./MscpVesting30M.sol");
var TestContract = artifacts.require("./TestContract.sol");



module.exports = async function(deployer, network) {

    let accounts = await web3.eth.getAccounts();
    console.log(accounts[0]);

    if (network == "ganache") {
      let startTime = Math.floor(Date.now()/1000) + 5;
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      // await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
      //     console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      // });
      await deployer.deploy(MscpVesting5M, MscpToken.address, startTime).then(function(){
          console.log("MscpVesting5M contract was deployed at address: "+MscpVesting5M.address);
      });
      await deployer.deploy(MscpVesting30M, MscpToken.address, startTime).then(function(){
          console.log("MscpVesting30M contract was deployed at address: "+MscpVesting30M.address);
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

    } else if (network == "moonbeam") {
      let startTime = Math.floor(Date.now()/1000) + 100;
      let mscpToken = "";
      await deployer.deploy(MscpToken).then(function(){
          console.log("Mscp token contract was deployed at address: "+MscpToken.address);
      });
      // await deployer.deploy(MscpVesting, MscpToken.address, startTime).then(function(){
      //     console.log("Mscp vesting contract was deployed at address: "+MscpVesting.address);
      // });

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
