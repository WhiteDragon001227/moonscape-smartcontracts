var mscp2moondust = artifacts.require("./mscpGame/ganeralDefi/MscpToMoondust.sol");

module.exports = function(deployer, _network) {
	deployer.deploy(mscp2moondust, "0x125d89902aA536930645C62498D14b18Cc21D29c").then(function(){
		console.log("mscp to moondust on address: " + mscp2moondust.address);
	});
};
