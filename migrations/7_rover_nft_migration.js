var nft = artifacts.require("./nfts/RoverNft.sol");

module.exports = function(deployer, _network) {
	deployer.deploy(nft).then(function(){
		console.log("Rover NFT on address: " + nft.address);
	});
};
