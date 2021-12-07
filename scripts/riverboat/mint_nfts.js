let Factory = artifacts.require("RiverboatFactory");
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

    // contracts
    let factory  = await Factory.at("0x2B57fc3a6bD98Aba718FCCe5554170B1315Ad691");
    let nft     = await Nft.at("0x0FA0A690D71430f1A2DA08E82Ba50f18DCAd452a");

    // global vars
    let receiver = "0xbf7843E2CeD5dedB99da23185aaB25962E9e8645";
    let type = 4;
    let amountToMint = 10;

    // fetch nft balance
    console.log("Checking receiver nft balance...");
    let balance = parseInt(await nft.balanceOf(receiver));
    console.log(`${receiver} owns ${balance} nfts`);

    // mint nfts
    console.log(`attemping to mint ${amountToMint} nfts...`);
    for(let i=0; i<amountToMint; i++){
        //let type = i % 5;
        let minted = await factory.mintType(receiver, type);

        // tokenId - get the last item in users wallet
        let tokenId = await nft.tokenOfOwnerByIndex(receiver, balance+i).catch(console.error);
        tokenId = parseInt(tokenId);
        console.log(`Nft ${i+1} with Id: ${tokenId}, type ${type} was minted`);
        // show progress - FIX IT
        // if(i > 0 && i % 4 == 0){
        //   let percentComplete = Math.round(i+2/amountToMint)*1000 / 100;
        //   console.log(`Minting ${percentComplete}% complete.`);
        // }
    }

    // fetch nft balance
    console.log("Checking receiver nft balance...");
    balance = await nft.balanceOf(receiver);
    console.log(`${receiver} owns ${balance} nfts`);

}.bind(this);
