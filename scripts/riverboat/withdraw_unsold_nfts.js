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

    let riverboat = await Riverboat.at("0x5434BDc9de2005278532F9041cBf3C939E48C4DC");
    let riverboatNft     = await RiverboatNft.at("0x115Aa9E35564307365Ca3f215f67eB69886f2fD1");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    // let sessionId = parseInt(await riverboat.sessionId.call());
    // sessionId = console.log(`last session id: ${sessionId}`);
    let receiverAddress = owner;

    let sessionId = 1;

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
      while(true){
        let tokenId = await riverboatNft.tokenOfOwnerByIndex(owner, 0).catch(console.error);
        tokenId = parseInt(tokenId);
        console.log(tokenId);
        if(tokenId == NaN)
          break;
        console.log("attempting to withdraw unsold nfts...");
        await nft.safeTransferFrom(riverboat.address, receiverAddress, tokenId, {from: owner});
        console.log(`${tokenId} was transfered`);
      }
    }



}.bind(this);
