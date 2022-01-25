let CityNftSale = artifacts.require("CityNftSale");
let CityNft = artifacts.require("CityNft");
let MscpToken = artifacts.require("MscpToken");

// global variables
let accounts;
let multiplier = 1000000000000000000;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {

    //--------------------------------------------------
    // Accounts and contracts configuration
    //--------------------------------------------------

    accounts = await web3.eth.getAccounts();
    let multiplier = 1000000000000000000;
    console.log(accounts);

    let cityNftSale = await CityNftSale.at("0xd2F438FdA5b95F3bdc3512aaC30526AeB2202455");
    let cityNft = await CityNft.at("0x14C7C9D806c7fd8c1B45d466B910c6AbF6428F07");
    let mscpToken = await MscpToken.at("0xF2C84Cb3d1e9Fac001F36c965260aA2a9c9D822D");


    let player = accounts[0];
    let verifier = accounts[0];
    console.log(`Using account ${player}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    // let sessionId = parseInt(await cityNftSale.sessionId.call());
    // console.log(`last session id: ${sessionId}`);
    // let nftId = parseInt(await cityNft.tokenOfOwnerByIndex(cityNftSale.address, 0));
    // console.log("nftId: " ,nftId);

    let sessionId = 32;
    let nftId = 44;
    //let currentInterval = 4
    let currentInterval = parseInt(await cityNftSale.getCurrentInterval(sessionId));
    console.log("currentInterval: " ,currentInterval);
    let chainId = parseInt(await cityNftSale.getChainId());
    console.log("chainId: " ,chainId);
    let currentPrice = (await cityNftSale.getCurrentPrice(sessionId, currentInterval)).toString();
    console.log("currentPrice: " ,currentPrice);
    let cityNftSaleAddress = cityNftSale.address;
    let currencyAddress = mscpToken.address;
    let nftAddress = cityNft.address;

    let amountToApprove = web3.utils.toWei("10000", "ether");


    // contract calls
    console.log("generating sig");
    let sig = await generateSig(sessionId, nftId, currentInterval, chainId,
      currentPrice, cityNftSaleAddress, currencyAddress, nftAddress);
    console.log("sig generated");
    //await approveMscpToken();
    //await buy();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // approve crowns and check allowance
    async function approveMscpToken(){
      console.log("attemping to approve MscpToken...");
      await mscpToken.approve(cityNftSale.address, amountToApprove, {from: player});
      console.log("checking allowance");
      let allowance = (await mscpToken.allowance(player, cityNftSale.address)).toString();
      console.log(`cityNftSale was approved to spend ${allowance/multiplier} MscpToken`);
    }

    // add currency address -only needs to run once per currency
    async function buy(){
        console.log(`attempting to buy nft...`);
        await cityNftSale.buy(sessionId, nftId, sig[0], sig[1], sig[2], {from: player});
        console.log(`bought nft id${nftId}`);
    }

    // --------------------------------------------------
    // Internal functions - digital signature part
    // --------------------------------------------------


    async function generateSig(sessionId, nftId, currentInterval, chainId,
      currentPrice, cityNftSaleAddress, currencyAddress, nftAddress){

      console.log("args to be passed into noPrefix: ", sessionId, nftId, currentInterval, chainId, currentPrice);
      let uints = web3.eth.abi.encodeParameters(
        ["uint256", "uint256", "uint256", "uint256", "uint256"],
        [sessionId, nftId, currentInterval, chainId, currentPrice]);

      // str needs to start with "0x"
      let str = uints + cityNftSaleAddress.substr(2) + currencyAddress.substr(2) + nftAddress.substr(2);
      let message = web3.utils.keccak256(str);
      console.log("message: ",message);
      let hash = await web3.eth.sign(message, verifier);
      console.log("hashed: ", hash)

      let r = hash.substr(0,66);
      let s = "0x" + hash.substr(66,64);
      let v = parseInt(hash.substr(130), 16);
      if (v < 27) {
          v += 27;
      }

      console.log("v: ",v);
      console.log("r: ",r);
      console.log("s: ",s);

      return [v, r, s];
    }

}.bind(this);
