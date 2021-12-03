var Riverboat = artifacts.require("./Riverboat.sol");
var RiverboatNft = artifacts.require("./RiverboatNft.sol");
var RiverboatFactory = artifacts.require("./RiverboatFactory.sol");






module.exports = async function(deployer, network) {
    let accounts = await web3.eth.getAccounts();
    console.log(accounts[0]);

    if (network == "ganache") {
        let priceReceiver = accounts[0];
        await deployer.deploy(Riverboat, priceReceiver).then(function(){
            console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        });
        await deployer.deploy(RiverboatNft).then(function(){
            console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        });
        await deployer.deploy(RiverboatFactory, RiverboatNft.address).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });

    } else if (network == "rinkeby") {
        var priceReceiver = accounts[0];
        console.log("receiver: " ,priceReceiver);
        var _RiverboatNft = "0x115Aa9E35564307365Ca3f215f67eB69886f2fD1";
        // await deployer.deploy(Riverboat, priceReceiver).then(function(){
        //     console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        // });
        // await deployer.deploy(RiverboatNft).then(function(){
        //     console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        // });
        await deployer.deploy(RiverboatFactory, _RiverboatNft).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });

    } else if (network == "bsctestnet") {
        var priceReceiver = accounts[0];
        var _RiverboatNft = "0x168840Df293413A930d3D40baB6e1Cd8F406719D";
        await deployer.deploy(Riverboat, priceReceiver).then(function(){
            console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        });
        await deployer.deploy(RiverboatNft).then(function(){
            console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        });
        await deployer.deploy(RiverboatFactory, _RiverboatNft).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });

    } else if (network == "moonbase") {
        let priceReceiver = accounts[0];
         var _RiverboatNft = "0x016f2b8fDF8F7c76b97a666fA31aBF064b1541B1";
        // await deployer.deploy(Riverboat, priceReceiver).then(function(){
        //     console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        // });
        // await deployer.deploy(RiverboatNft).then(function(){
        //     console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        // });
        await deployer.deploy(RiverboatFactory, _RiverboatNft).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });

    } else if (network == "mainnet") {
        var _RiverboatNft = "0x168840Df293413A930d3D40baB6e1Cd8F406719D";
        await deployer.deploy(Riverboat, priceReceiver).then(function(){
            console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        });
        await deployer.deploy(RiverboatNft).then(function(){
            console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        });
        await deployer.deploy(RiverboatFactory, _RiverboatNft).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });

    } else if (network == "bsc") {
        var _RiverboatNft = "0x168840Df293413A930d3D40baB6e1Cd8F406719D";
        await deployer.deploy(Riverboat, priceReceiver).then(function(){
            console.log("Riverboat contract was deployed at address: "+Riverboat.address);
        });
        await deployer.deploy(RiverboatNft).then(function(){
            console.log("RiverboatNft contract was deployed at address: "+RiverboatNft.address);
        });
        await deployer.deploy(RiverboatFactory, _RiverboatNft).then(function(){
            console.log("RiverboatFactory contract was deployed at address: "+RiverboatFactory.address);
        });
    }
};
