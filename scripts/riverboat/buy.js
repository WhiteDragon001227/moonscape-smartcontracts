let Riverboat = artifacts.require("Riverboat");
let RiverboatNft = artifacts.require("RiverboatNft");
let Rib = artifacts.require("Rib");

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

    let riverboat = await Riverboat.at("0xfF6d9a52A37FccFa1dd5df767B68D39451E4b974");
    let riverboatNft = await RiverboatNft.at("0x016f2b8fDF8F7c76b97a666fA31aBF064b1541B1");
    let rib = await Rib.at("0xE29A4BD665e4782a4c002aA30D3d25f010E8A394");


    let player = accounts[0];
    let owner = accounts[0];
    console.log(`Using account ${player}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let sessionId = parseInt(await riverboat.sessionId.call());
    console.log(`last session id: ${sessionId}`);
    // let nftId = parseInt(await riverboatNft.tokenOfOwnerByIndex(riverboat.address, 0));
    // console.log("nftId: " ,nftId);

    // let sessionId = 1;
    let nftId = 16;
    //let currentInterval = 4
    let currentInterval = parseInt(await riverboat.getCurrentInterval(sessionId));
    console.log("currentInterval: " ,currentInterval);
    let chainId = parseInt(await riverboat.getChainId());
    console.log("chainId: " ,chainId);
    let currentPrice = (await riverboat.getCurrentPrice(sessionId, currentInterval)).toString();
    console.log("currentPrice: " ,currentPrice);
    let riverboatAddress = riverboat.address;
    let currencyAddress = rib.address;
    let nftAddress = riverboatNft.address;

    let amountToApprove = web3.utils.toWei("1", "ether");


    // contract calls
    console.log("generating sig");
    let sig = await generateSig(sessionId, nftId, currentInterval, chainId,
      currentPrice, riverboatAddress, currencyAddress, nftAddress);
    console.log("sig generated");
    //await approveRib();
    //await buy();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // approve crowns and check allowance
    async function approveRib(){
      console.log("attemping to approve Rib...");
      await rib.approve(riverboat.address, amountToApprove, {from: player});
      console.log("checking allowance");
      let allowance = (await rib.allowance(player, riverboat.address)).toString();
      console.log(`riverboat was approved to spend ${allowance/multiplier} Rib`);
    }

    // add currency address -only needs to run once per currency
    async function buy(){
        console.log(`attempting to buy nft...`);
        await riverboat.buy(sessionId, nftId, sig[0], sig[1], sig[2], {from: player});
        console.log(`bought nft id${nftId}`);
    }

    // --------------------------------------------------
    // Internal functions - digital signature part
    // --------------------------------------------------


    async function generateSig(sessionId, nftId, currentInterval, chainId,
      currentPrice, riverboatAddress, currencyAddress, nftAddress){

      console.log("args to be passed into noPrefix: ", sessionId, nftId, currentInterval, chainId, currentPrice);
      let uints = web3.eth.abi.encodeParameters(
        ["uint256", "uint256", "uint256", "uint256", "uint256"],
        [sessionId, nftId, currentInterval, chainId, currentPrice]);

      // str needs to start with "0x"
      let str = uints + riverboatAddress.substr(2) + currencyAddress.substr(2) + nftAddress.substr(2);
      let message = web3.utils.keccak256(str);
      console.log("message: ",message);
      let hash = await web3.eth.sign(message, owner);
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
