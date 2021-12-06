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

    let riverboat = await Riverboat.at("0xfF6d9a52A37FccFa1dd5df767B68D39451E4b974");
    let riverboatNft     = await RiverboatNft.at("0x016f2b8fDF8F7c76b97a666fA31aBF064b1541B1");


    let owner = accounts[0];
    console.log(`Using account ${owner}`);

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    // let sessionId = parseInt(await riverboat.sessionId.call());
    // sessionId = console.log(`last session id: ${sessionId}`);
    let receiverAddress = owner;

    let sessionId = 3;

    // contract calls
    // await approveUnsoldNfts();
    await withdrawNfts();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // approve withdrawal of unsold nfts - after session end
    async function approveUnsoldNfts(){
      console.log("attempting to approve unsold nfts...");
      await riverboat.approveUnsoldNfts(sessionId, receiverAddress, {from: owner});

      console.log("Checking if Nfts are approved ?")
      let approved = await riverboatNft.isApprovedForAll(riverboat.address, receiverAddress);
      console.log(approved);
    }

    async function withdrawNfts(){
      while(true){
        let tokenId = await riverboatNft.tokenOfOwnerByIndex(riverboat.address, 0).catch(console.error);
        tokenId = parseInt(tokenId);
        if(tokenId == NaN){
          console.log("no more nfts in the contract");
          break;
        }
        // TODO check allowance for given nftId

        console.log(`attempting to withdraw nft id ${tokenId}`);
        await riverboatNft.safeTransferFrom(riverboat.address, receiverAddress, tokenId, {from: owner});
        console.log(`${tokenId} was transfered`);
      }
    }



}.bind(this);
