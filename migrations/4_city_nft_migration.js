var nft = artifacts.require("./nfts/CityNft.sol");

module.exports = function(deployer, _network) {
	deployer.deploy(nft).then(function(){
		console.log("City NFT on address: " + nft.address);
	});
};
