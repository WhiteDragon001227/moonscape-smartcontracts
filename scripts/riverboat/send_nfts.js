let Nft = artifacts.require("RiverboatNft");


let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};

let init = async function(networkId) {
    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    let nft = await Nft.at("0x115Aa9E35564307365Ca3f215f67eB69886f2fD1");

    // return current account and sessionId
    let user = accounts[0];
    console.log(`Using ${user}`);


    // fetch nftIds
    let receiver = "0x5434BDc9de2005278532F9041cBf3C939E48C4DC";
    let amount = 100;
    console.log(`attempting to send nfts...`);
    for(let index = 0; index < amount; index++){
      let tokenId = await nft.tokenOfOwnerByIndex(user, 0);
      tokenId = parseInt(tokenId.toString());
      await nft.safeTransferFrom(user, receiver, tokenId);

      console.log(`Nft with id ${tokenId} was sent.`);
    }



}.bind(this);
