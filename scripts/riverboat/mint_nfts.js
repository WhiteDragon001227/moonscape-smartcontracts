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
    let factory  = await Factory.at("0xF29af81595f575d88447C69B6a760862e6EB30eC");
    let nft     = await Nft.at("0x016f2b8fDF8F7c76b97a666fA31aBF064b1541B1");

    // global vars
    let receiver = "0xfF6d9a52A37FccFa1dd5df767B68D39451E4b974";
    //let type = 0;
    let amountToMint = 24;


    // let tokenId = await nft.tokenOfOwnerByIndex(receiver, 11).catch(console.error);
    // tokenId = parseInt(tokenId);
    // console.log(`Nft ${tokenId}`);

    // mint nfts
    console.log(`attemping to mint ${amountToMint} nfts...`);
    for(let i=0; i<=amountToMint; i++){
        let type = i % 5;
        let minted = await factory.mintType(receiver, type);

        // tokenId - get the last item in users wallet
        let tokenId = await nft.tokenOfOwnerByIndex(receiver, balance+i).catch(console.error);
        tokenId = parseInt(tokenId);
        console.log(`Nft ${i+1} with Id: ${tokenId}, type ${type} was minted`);
        // show progress
        if(i % 5 == 0){
          let percentComplete = Math.round(i/amountToMint*10000) / 100;
          console.log(`Minting ${percentComplete}% complete.`);
        }
    }

    // // fetch nft balance
    console.log("Checking receiver nft balance...");
    balance = await nft.balanceOf(receiver);
    console.log(`${receiver} owns ${balance} nfts`);

}.bind(this);
