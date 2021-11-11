var Rib = artifacts.require("./RIB.sol");

module.exports = function(deployer, _network) {
		deployer.deploy(Rib).then(function(){
			console.log("Rib on address: "+Rib.address);
		});
};
