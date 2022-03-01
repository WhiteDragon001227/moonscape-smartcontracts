var contract = artifacts.require("./game/MoonscapeGame.sol");

// 0x187574887e757Cb86276c36dcB51082C723A67F6 on moonbase v1 with bug
// 0xacd424377939fE7a5631F3139BD9e3495AFAdeD2 on moonbase v2 fixed
module.exports = function(deployer, _network) {
	deployer.deploy(contract, 
        "0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D",                   // mscp
        "0xffa086A32259be131b6a643D034512881A6B0f51",					// city
        "0xA2093C326b01c263f74435f26d8D2b2523BFA772",					// rover
        "0x9ceAB9b5530762DE5409F2715e85663405129e54",					// scape
        "0xC6EF8A96F20d50E347eD9a1C84142D02b1EFedc0",                   // verifier
        "0xC6EF8A96F20d50E347eD9a1C84142D02b1EFedc0").then(function(){ 	// fee to
		console.log("Moonscape game on address: " + contract.address);
	});
};
