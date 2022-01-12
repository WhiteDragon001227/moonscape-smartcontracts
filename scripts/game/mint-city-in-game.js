let City = artifacts.require("CityNft");
let Game = artifacts.require("MoonscapeGame");

// global variables
let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function() {

    //--------------------------------------------------
    // Accounts and contracts configuration
    //--------------------------------------------------

    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let game = await Game.at("0x187574887e757Cb86276c36dcB51082C723A67F6");
    let city = await City.at("0xffa086A32259be131b6a643D034512881A6B0f51");

    let owner = accounts[0];
    console.log(`Using account ${owner}`);
    console.log(`City ${city.address}, Game: ${game.address}`);


    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------
    let cityId = 1641969293640;
    let category = 2;
    let amountWei = web3.utils.toWei("1");

    let signature = await fetchMintCitySignature(owner, cityId, category, amountWei);
    console.log(`Signature to use ${signature}`);
    let vrs = fetchVrs(signature);
    console.log(`VRS: `, vrs)

    await mintCity(cityId, category, amountWei, vrs);

    // "0x034410968b3739ddd11edfac0e0664eac164a9f7444355ba68e104d8f0d28ece7c3c520145a457e1c88e8a79dc48362be832d3a7093e7a7b711cdc0a00c9bd861b"

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    async function mintCity (cityId, category, amountWei, vrs) {
        console.log(`Minting city ${cityId} of category ${category} by spending ${amountWei/1e18} Moondust...`);
        // await game.mintCity(cityId, category, amountWei, vrs[0], vrs[1], vrs[2], {from: owner}).catch(console.error);
        console.log(`${cityId} was minted for ${owner}`);
    }

    async function fetchMintCitySignature (user, cityId, category, amount) {
        //v, r, s related stuff
        let bytes32 = web3.eth.abi.encodeParameters(["uint256", "uint256"], [cityId, amount]);
        let bytes1 = web3.utils.bytesToHex([category]);

        let str = user
                + game.address.substr(2)
                + city.address.substr(2)
                + bytes32.substr(2)
                + bytes1.substr(2);

        let data = web3.utils.keccak256(str);
        // signature:
        // "0x377ead0db3f1729820e38d6d806f5ba2d40771c148e12762d621309f6c96217f6b675fbfc8d86bca35a2473171a3c9a847d1e69e30c863c47f6085aac67feae21b"
        // data:
        // 0x68c5899e02653b3fb4af5e62804053c8394be2117c7fda34935204d25571f402
        console.log(`Message to sign: ${data}`);
        try {
            return await web3.eth.sign(data, owner);
        } catch(error)  {
            console.error(error);
            return "";
        };
    }

    function fetchVrs (signature) {
        let r = signature.substr(0, 66);
        let s = "0x" + signature.substr(66, 64);
        let v = parseInt(signature.substr(130), 16);
        if (v < 27) {
            v += 27;
        }
        return [v, r, s];
    }
}.bind(this);
