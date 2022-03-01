var singleTokenStaking = artifacts.require("./mscpGame/ganeralDefi/SingleTokenStaking.sol");

module.exports = function(deployer, _network) {
	deployer.deploy(singleTokenStaking).then(function(){
		console.log("single token staking on address: " + singleTokenStaking.address);
	});
};
