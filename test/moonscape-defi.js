
var Mscp = artifacts.require("./MscpToken.sol");
var City = artifacts.require("./CityNft.sol");
var Defi = artifacts.require("./MoonscapeDefi.sol");

async function signStakeToken(stake_id, session_id, city_id, building_id) {
  //v, r, s related stuff
  let bytes32 = web3.eth.abi.encodeParameters(["uint256", "uint256", "uint256", "uint256"],[stake_id, session_id, city_id, building_id]);
  let data = web3.utils.keccak256(bytes32);
  let hash = await web3.eth.sign(data, gameOwner);

  let r = hash.substr(0,66);
  let s = "0x" + hash.substr(66,64);
  let v = parseInt(hash.substr(130), 16);
  if (v < 27) {
      v += 27;
  }
  return [v, r, s];
}

contract("Moonscape Defi", async accounts => {
  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  ///////////// GLOBAL VARS ///////////////

  // imported contracts
  let defi      = null;
  let mscp      = null;
  let city      = null;
  let scape     = null;

  // session & accounts data
  let player    = null;
  let gameOwner = null;

  let stakeId   = null;

  // support variables
  let finney    = 1000000000000000;
  let ether     = 1000000000000000000;

  it("1 should link contracts", async () => {
    gameOwner = accounts[0];
    player    = accounts[1];

    mscp      = await Mscp.new();
    city      = await City.new();
    scape     = await City.new();
    rover     = await Rover.new();
    defi      = await Defi.new();
  });

  it("2 should start a new defi session", async () => {
    let startTime = Math.floor(Date.now()/1000) + 120;
    let endTime = startTime + 3600;

    console.log(`starting session...`);
    await defi.startSession(startTime, endTime, {from: gameOwner});
    console.log(`session started!`);

    let lastSessionId = await defi.sessionId();
    console.log("last session id is: ", lastSessionId);
  });

  it("3 should failed when start a new seesion while session is active", async () => {
    let sessionId = await defi.sessionId();

    let startTime = Math.floor(Date.now()/1000) + 120;
    let endTime = startTime + 3600;

    try{
      await defi.startSession(startTime, endTime, {from: gameOwner});
      assert.fail();
    }catch(e){
      assert.equal(e.reason, "session is not active", "buy function should return an error");
    }
  });

  it("3 should pause the session", async () => {
    let sessionId = await defi.sessionId();

    await defi.pauseSession(sessionId);
    console.log("session is paused");

    let status = await defi.sessions(sessionId);
    console.log("now session status: ", status.active);
  });

  it("4 should add a staking option", async () => {
    let sessionId = await defi.sessionId();
    let rewardNumber = web3.utils.toWei("10000","ether");

    console.log("transfer some mscp to contract as reward");
    await mscp.transfer(defi.address, rewardNumber, {from: gameOwner});

    console.log("add staking ...");
    await defi.addTokenStaking(sessionId, mscp.address, rewardNumber, mscp.address, {from: gameOwner});

    stakeId = await defi.stakeId();
    console.log("this staking id is:", stakeId);
  });

  // Depositing mscp token to Smartcontract.
  // However, before deposit, it should be approved to Smartcontract
  it("5 should approve to deposit some token", async() => {
    let depositAmount = web3.utils.toWei("100", "ether");
    await mscp.approve(defi.address, depositAmount, {from: gameOwner});

    let allowance = await mscp.allowance.call(gameOwner, defi.address);
    assert.equal(allowance, depositAmount, "Deposit amount of Lp Tokens were not allowed to be transferred");
  });


  it("6 should deposit a staking token", async() => {
    let depositAmount = web3.utils.toWei("100", "ether");
    let sessionId = await defi.sessionId();

    let signature = await signStakeToken(stakeId, sessionId, 1, 1);

    console.log("deposit tokens into contract");
    await defi.stakeToken(stakeId, 1, 1, depositAmount, signature.v, [signature.r, signature.s], {from: gameOwner});
  });

  it("7 should claim rewards", async() => {
    let depositAmount = web3.utils.toWei("100", "ether");

    try {
	    await defi.claim(stakeId, {from: gameOwner});
    } catch(e) {
        assert.fail('Nothing was generated to claim');
        return;
    }
  });

  it("8 should unstake tokens", async() => {
    let unstakeAmount = web3.utils.toWei("100", "ether");

    await lpMining.unstake(stakeId, unstakeAmount, {from: gameOwner});
    console.log("withdraw success");
  });

});
