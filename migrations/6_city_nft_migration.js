var CityNft = artifacts.require("./CityNft.sol");
var CityNftSale = artifacts.require("./CityNftSale.sol");
var CityFactory = artifacts.require("./CityFactory.sol");






module.exports = async function(deployer, network) {
    let accounts = await web3.eth.getAccounts();
    console.log(`using ${accounts[0]}`);

    if (network == "ganache") {
        var priceReceiver = accounts[0];
        var verifier = accounts[0];

        await deployer.deploy(CityNftSale, priceReceiver, verifier).then(function(){
            console.log("CityNftSale contract was deployed at address: "+CityNftSale.address);
        });
        await deployer.deploy(CityNft).then(function(){
            console.log("CityNft contract was deployed at address: "+CityNft.address);
        });
        await deployer.deploy(CityFactory, CityNft.address).then(function(){
            console.log("CityFactory contract was deployed at address: "+CityFactory.address);
        });

    } else {
        var priceReceiver = accounts[0];
        console.log("receiver: " ,priceReceiver);
        var verifier = accounts[0];
        var _CityNft = "0xb807A3F0AF8dD50725DB01d0723930bB0DB9837f";

        // await deployer.deploy(CityNftSale, priceReceiver, verifier).then(function(){
        //     console.log("CityNftSale contract was deployed at address: "+CityNftSale.address);
        // });
        // await deployer.deploy(CityNft).then(function(){
        //     console.log("CityNft contract was deployed at address: "+CityNft.address);
        // });
        await deployer.deploy(CityFactory, _CityNft).then(function(){
            console.log("CityFactory contract was deployed at address: "+CityFactory.address);
        });
    }
};
