let RibToken = artifacts.require("Rib");

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

    let ribToken = await RibToken.at("0xB60590313975f0d98821B6Cab5Ea2a6d9641D7B6");

    //--------------------------------------------------
    // Parameters setup and function calls
    //--------------------------------------------------

    let bridge = "0x911F32FD5d347b4EEB61fDb80d9F1063Be1E78E6";
    let newOwner = "0x155E13c0a337e80f5924732706Efe858D7003c20";
    let investorAddress = "";

    // contract calls
    // await toggleBridgeAllowance();
    // await addBridge();
    await transferOwnership();

    async function toggleBridgeAllowance(){
      console.log("checking if bridge is allowed")
      let bridgeAllowed = await ribToken.bridgeAllowed.call();
      console.log(bridgeAllowed);
      if(!bridgeAllowed){
        console.log("attempting to toggle bridge...");
        await ribToken.toggleBridgeAllowance();
        console.log(`bridge toggled.`);
        console.log("checking if bridge is allowed")
        bridgeAllowed = await ribToken.bridgeAllowed.call();
        console.log(bridgeAllowed);
      }
    }

    async function addBridge(){
      console.log("checking if bridge is added")
      let isBridge = await ribToken.bridges(bridge);
      console.log(isBridge);
      if(!isBridge){
        console.log("attempting to add bridge...");
        await ribToken.addBridge(bridge);
        console.log(`bridge added`);
      }
      console.log("checking if bridge is added")
      isBridge = await ribToken.bridges(bridge);
      console.log(isBridge);
    }

    async function transferOwnership(){
      let owner = await ribToken.owner();
      if(owner == newOwner){
        console.log(`current owner is the same as new - ${owner}`);
      } else {
        console.log(`current owner is ${owner}`);
        console.log("attempting to transfer ownership...")
        await ribToken.transferOwnership(newOwner);
        console.log("ownership has been transfered");
        owner = await ribToken.owner();
        console.log(`new owner is ${owner}`);
      }
    }

}.bind(this);
