var Rib = artifacts.require("./Rib.sol");

module.exports = function(deployer, _network) {
		deployer.deploy(Rib).then(function(){
			console.log("Rib on address: "+Rib.address);
		});
};
