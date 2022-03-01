var MscpPrivateVesting = artifacts.require("./MscpPrivateVesting.sol");
var MscpToken = artifacts.require("./MscpToken.sol");




contract("MscpPrivateVesting", async accounts => {


  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }


///////////// GLOBAL VARS ///////////////

  const ether = 1000000000000000000;
  const supply = 4250000;
  const reward = 750000;

  // imported contracts
  let mscpPrivateVesting = null;
  let mscpToken = null;

  // session & accounts data
  let privateInvestor1 = null;
  let privateInvestor2 = null;
  let maliciousInvestor = null;
  let owner = null;

  // balances data
  let privateBalance1;
  let privateBalance2;


  it("0.1 should link mscp token and mscp vesting contracts", async () => {
    mscpPrivateVesting = await MscpPrivateVesting.deployed();
    mscpToken = await MscpToken.deployed();
    owner = accounts[0];
    privateInvestor1 = accounts[1];
    privateInvestor2 = accounts[2];
    maliciousInvestor = accounts[3];
  });

  it("1. should mint mscpTokens and transfer them to vesting contract", async () => {
    let mintingAmount = 1111111111;   // 1.1 billion
    let transferValue = "10000000";   // 10 million
    let transferAmount = web3.utils.toWei(transferValue, "ether");

    //balanceof owner
    let ownerBalance = parseInt(await mscpToken.balanceOf(owner))/ether;
    assert.equal(1111111111, ownerBalance, "owner received insufficient tokens");

    //transfer to contract
    mscpToken.transfer(mscpPrivateVesting.address, transferAmount, {from: owner});
    let contractBalance = parseInt(await mscpToken.balanceOf(mscpPrivateVesting.address))/ether;
    assert.equal(transferValue, contractBalance, "contract received insufficient tokens");
  });

  it("2. should add investors", async () => {
    await mscpPrivateVesting.addInvestor(privateInvestor1);
    let allocationPrivateInvestor1 = await mscpPrivateVesting.getAllocation(privateInvestor1);
    allocationPrivateInvestor1 = parseInt(allocationPrivateInvestor1)/ether;
    assert.equal(allocationPrivateInvestor1, supply, "invalid privateInvestor1 allocation");

    await mscpPrivateVesting.addInvestor(privateInvestor2);
    let allocationPrivateInvestor2 = await mscpPrivateVesting.getAllocation(privateInvestor2);
    allocationPrivateInvestor2 = parseInt(allocationPrivateInvestor2)/ether;
    assert.equal(allocationPrivateInvestor2, supply, "invalid privateInvestor2 allocation");

    await mscpPrivateVesting.addInvestor(maliciousInvestor);
  });

  it("3. should not be able to withdraw before session starts", async () => {
    try{
      await mscpPrivateVesting.withdraw({from: privateInvestor1});
      assert.fail();
    }catch(e){
      assert.equal(e.reason, "vesting hasnt started yet", "withdraw function should return an error");
    }
  });

  it("wait until session starts", async () => {
    await sleep(2000);
    let allocation = await mscpPrivateVesting.getAllocation(privateInvestor1);
    assert(true);
  });

  it("4. attacker should not be able to withdraw without allocation", async () => {
    try{
      await mscpPrivateVesting.withdraw({from: accounts[4]});
      assert.fail();
    }catch(e){
      assert.equal(e.reason, "user has no allocation", "withdraw function should return an error");
    }
  });

  it("5. privateInvestor1 should be able to withdraw proper amount (with bonus)", async () => {
    await mscpPrivateVesting.withdraw({from: privateInvestor1});
    privateBalance1 = parseInt(await mscpToken.balanceOf(privateInvestor1))/ether;
    console.log("privateInvestor1 balance: " ,privateBalance1);
    assert.isAbove(privateBalance1, reward, "privateInvestor1 received insufficient funds");
  });

  it("6. privateInvestor2 should be able to withdraw proper amount (with bonus)", async () => {
    await mscpPrivateVesting.withdraw({from: privateInvestor2});
    privateBalance2 = parseInt(await mscpToken.balanceOf(privateInvestor2))/ether;
    console.log("privateInvestor2 balance: " ,privateBalance2);
    assert.isAbove(privateBalance2, reward, "privateInvestor2 received insufficient funds");
  });

  it("7. should be able to remove malicious investor", async () => {
    await mscpPrivateVesting.disableInvestor(maliciousInvestor);
    let allocation = parseInt(await mscpPrivateVesting.getAllocation(maliciousInvestor));
    assert.equal(allocation, 0, "malicious investor should have 0 remaining coins");
  });

  it("8. privateInvestor1 and privateInvestor2 should be able to withdraw again", async () => {
    await mscpPrivateVesting.withdraw({from: privateInvestor1});
    let newPrivateBalance1 = parseInt(await mscpToken.balanceOf(privateInvestor1))/ether;
    console.log("new privateInvestor1 balance: " ,newPrivateBalance1);
    assert.isAbove(newPrivateBalance1, privateBalance1, "invalid privateInvestor1 balances");

    await mscpPrivateVesting.withdraw({from: privateInvestor2});
    let newPrivateBalance2 = parseInt(await mscpToken.balanceOf(privateInvestor2))/ether;
    console.log("new privateInvestor2 balance: " ,newPrivateBalance2);
    assert.isAbove(newPrivateBalance2, privateBalance2, "invalid privateInvestor2 balances");
  });

  it("9. malicious investor should not be able to withdraw again", async () => {
      try{
        await mscpPrivateVesting.withdraw({from: maliciousInvestor});
        assert.fail();
      }catch(e){
        assert.equal(e.reason, "user has no allocation", "withdraw function should return an error");
      }
    });

  it("wait until session is finished", async () => {
    await sleep(6000);
    let allocation = await mscpPrivateVesting.getAllocation(privateInvestor1);
    assert(true);
  });

  it("10. privateInvestor1 should have proper balances after final withdraw", async () => {
    await mscpPrivateVesting.withdraw({from: privateInvestor1});
    privateBalance1 = parseInt(await mscpToken.balanceOf(privateInvestor1))/ether;
    console.log("final privateInvestor1 balance: " ,privateBalance1);
    assert.equal(privateBalance1, 5000000, "invalid privateInvestor1 balances");
  });

  it("11. private investor should have proper balances after final withdraw", async () => {
    await mscpPrivateVesting.withdraw({from: privateInvestor2});
    privateBalance2 = parseInt(await mscpToken.balanceOf(privateInvestor1))/ether;
    console.log("final privateInvestor2 balance: " ,privateBalance2);
    assert.equal(privateBalance2, 5000000, "invalid privateInvestor2 balances");
  });

  it("12. privateInvestor1 should not be able to withdraw again", async () => {
    try{
      await mscpPrivateVesting.withdraw({from: privateInvestor1});
      assert.fail();
    }catch(e){
      assert.equal(e.reason, "user has no allocation", "withdraw function should return an error");
    }
  });
});
