let Factory = artifacts.require("CityFactory");
let Nft = artifacts.require("CityNft");

let accounts;

module.exports = async function(callback) {
    const networkId = await web3.eth.net.getId();
    let res = await init(networkId);
    callback(null, res);
};


let init = async function(networkId) {
    accounts = await web3.eth.getAccounts();
    console.log(accounts);

    //--------------------------------------------------
    // Addresses setup
    //--------------------------------------------------

    // contracts
    let factory  = await Factory.at("0xCC72101FD4F7DDCd222D4774595499c24A1c18cC");
    let nft     = await Nft.at("0x14C7C9D806c7fd8c1B45d466B910c6AbF6428F07");

    //--------------------------------------------------
    // Parameters setup
    //--------------------------------------------------

    // global vars
    let receiver = "0xd2F438FdA5b95F3bdc3512aaC30526AeB2202455";
    let tokenId = 36;
    let amountToMint = 10;
    let category = 0;   //automatically assigned in mint()

    //--------------------------------------------------
    // Function calls setup
    //--------------------------------------------------

    await getNftBalance();
    await mintNfts();
    await getNftBalance();

    //--------------------------------------------------
    // Functions operating the contract
    //--------------------------------------------------

    // fetch receivers nft balance
    async function getNftBalance(){
      console.log("Checking receiver nft balance...");
      let balance = parseInt(await nft.balanceOf(receiver));
      console.log(`${receiver} owns ${balance} nfts`);
    }

    // mint nfts
    async function mintNfts(){
      console.log(`attemping to mint ${amountToMint} nfts...`);
      if(amountToMint>99)
          throw new Error("cant mint more than 99 nfts at once!");

      for(let i=0; i<amountToMint; i++){

          // if(tokenId>=100 && tokenId<200)
          //   category = 4;
          // else if(tokenId>=200 && tokenId<300)
          //   category = 3;
          // else if(tokenId>=300 && tokenId<400)
          //   category = 2;
          // else if(tokenId>=400 && tokenId<500)
          //   category = 1;
          // else if(tokenId>=500 && tokenId<600)
          //   category = 0;
          // else
          //   throw new Error("invalid tokenId (should be 100-599)!");

          let minted = await factory.mint(tokenId, category, receiver).catch(console.error);
          console.log(`Nft ${i+1} with Id: ${tokenId}, category ${category} was minted`);
          tokenId++;

          // show progress - FIX IT
          // if(i > 0 && i % 4 == 0){
          //   let percentComplete = Math.round(i+2/amountToMint)*1000 / 100;
          //   console.log(`Minting ${percentComplete}% complete.`);
          // }
      }
    }

}.bind(this);
