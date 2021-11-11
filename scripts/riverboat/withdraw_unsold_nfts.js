let Riverboat = artifacts.require("Riverboat");
let RiverboatNft = artifacts.require("RiverboatNft");


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
    console.log(accounts);

    let riverboat = await Riverboat.at("0x8E61f5028eEA48fdd58FD3809fc2202ABdBDC126");
    let riverboatNft     = await RiverboatNft.at("0x7115ABcCa5f0702E177f172C1c14b3F686d6A63a");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let sessionId = parseInt(await riverboat.lastSessionId.call());
    sessionId = console.log(`last session id: ${sessionId}`);
    let receiverAddress = owner;

    // contract calls
    await approveUnsoldNfts();
    await withdrawNfts();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // approve withdrawal of unsold nfts - after session end
    async function approveUnsoldNfts(){
      console.log("attempting to approve unsold nfts...");
      await riverboat.approveUnsoldNfts(sessionId, receiverAddress, {from: owner});

      console.log("Checking if Nfts are approved ?")
      let approved = await riverboatNft.isApprovedForAll(receiverAddress, riverboat.address);
      console.log(approved);
    }

    async function withdrawNfts(){
      let tokenId;
      while(true){
      let tokenId = await riverboatNft.tokenOfOwnerByIndex(owner, 0).catch(console.error);
      tokenId = parseInt(tokenId.toString());
      if(tokenId == NaN)
        break;
      console.log("attempting to withdraw unsold nfts...");
      await nft.safeTransferFrom(riverboat.address, 0);
      console.log(`${tokenId} was transfered`);
      }
    }



}.bind(this);
