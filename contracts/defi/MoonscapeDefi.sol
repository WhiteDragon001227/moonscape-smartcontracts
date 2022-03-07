pragma solidity 0.6.7;

import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Stake.sol";

contract MoonscapeDefi is Stake, IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    uint public sessionId;
    uint public stakeId;

    struct Session {
        uint startTime; // session start time
        uint endTime;   // session end time
        bool active;    // check session is active or not
    }

    struct TokenStaking {
        uint sessionId;
        address stakeToken;   // staked token address
        uint rewardPool;      // reward token number
        address rewardToken;  // reward token address
    }

    mapping(uint => Session) public sessions;
    mapping(bytes32 => bool) public addedStakings;
    mapping(uint => TokenStaking) public tokenStakings; //uint stakeId => TokenStaking
    mapping(bytes32 => uint) public keyToId;            //bytes32 key(通过stakeKeyOf(sessionId,stakeId)获得stakeKey) => value(stakeId)

    event StartSession(uint indexed sessionId, uint startTime, uint endTime);
    event PauseSession(uint indexed sessionId);
    event ResumeSession(uint indexed sessionId);
    event AddStaking(uint indexed sessionId, uint indexed stakeId);

    constructor () public {}

    /// @dev start a new session
    function startSession(uint _startTime, uint _endTime) external {
        require(validSessionTime(_startTime, _endTime), "INVALID_SESSION_TIME");

        sessionId++;

        sessions[sessionId] = Session(_startTime, _endTime, true);

        emit StartSession(sessionId, _startTime, _endTime);
    }

    /// @dev pause session
    function pauseSession(uint _sessionId) external {
        Session storage session = sessions[_sessionId];
        require(isActive(_sessionId), "session is not start, can't pause");
        require(session.active, "INACTIVE");

        session.active = false;

        emit PauseSession(_sessionId);
    }

    /// @dev resume session, make it active
    function resumeSession(uint _sessionId) external {
        Session storage session = sessions[_sessionId];
        require(isActive(_sessionId), "session is not start, can't resume");
        require(session.endTime > 0 && !session.active, "ACTIVE");

        session.active = true;

        emit ResumeSession(_sessionId);
    }

    /// @dev add token staking to session
    function addTokenStaking(uint _sessionId, address stakeAddress, uint rewardPool, address rewardToken) external {
        bytes32 key = keccak256(abi.encodePacked(_sessionId, stakeAddress, rewardToken));

        require(!addedStakings[key], "DUPLICATE_STAKING");

        addedStakings[key] = true;

        tokenStakings[++stakeId] = TokenStaking(_sessionId, stakeAddress, rewardPool, rewardToken);

        bytes32 stakeKey = stakeKeyOf(sessionId, stakeId);

        keyToId[stakeKey] = stakeId;

        Session storage session = sessions[_sessionId];

        newStakePeriod(
            stakeKey,
            session.startTime,
            session.endTime,
            rewardPool    
        );

        emit AddStaking(_sessionId, stakeId);
    }

    /// @dev stake tokens
    function stakeToken(uint _stakeId, uint _cityId, uint _buildingId, uint _amount, uint8 v, bytes32[2] calldata sig) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // todo
        // validate the session id
        require(isActive(tokenStaking.sessionId), "session not active");

        //validate stake id
        require(_stakeId <= stakeId,"do not have this stakeId");


        bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
        bytes32 message         = keccak256(abi.encodePacked(_stakeId, tokenStaking.sessionId, _cityId, _buildingId));
        bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        address recover         = ecrecover(hash, v, sig[0], sig[1]);


        require(recover == owner(), "Verification failed");

        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        deposit(stakeKey, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);

        require(token.balanceOf(msg.sender) >= _amount, "Not enough token to stake");
        // uint preBalance = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // _amount = token.balanceOf(address(this)) - preBalance;
    }

    /// @dev withdraw tokens
    function unstakeToken(uint _stakeId, uint _amount) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // todo
        // validate the session id

        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        withdraw(stakeKey, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);

        // uint preBalance = token.balanceOf(address(this));

        token.safeTransfer(msg.sender, _amount);

        // _amount = token.balanceOf(address(this)) - preBalance;
    }

    /// @dev claim rewards
    function claim(uint _stakeId)
        external
        returns(uint256)
    {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        return reward(stakeKey, msg.sender);
    }

    /// @dev get bonus reward after session is ended
    function getBonus(uint _stakeId, uint _cityId, uint _buildingId, uint _bonusPercent, uint8 _v, bytes32 _r, bytes32 _s) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];
        Session storage session = sessions[tokenStaking.sessionId];

        // require(block.timestamp > session.endTime, "it has to be after the session");

        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);
        StakeUser storage staker    = stakeUsers[stakeKey][msg.sender];

        require(staker.receiveBonus == true, "already rewarded");

        require(verifyBonus(tokenStaking.sessionId, _stakeId, _cityId, _buildingId, _bonusPercent, _v, _r, _s), "bonus signature is invalid");


        uint256 _totalreward = claimable(stakeKey, msg.sender) + staker.claimedAmound;
        uint256 _totalBonus  = _totalreward.mul(scaler).mul(_bonusPercent).div(100).div(scaler);

        IERC20 token = IERC20(tokenStaking.rewardToken);
        token.safeTransfer(msg.sender, _totalBonus);

        staker.receiveBonus = true;
    }

    /// @dev verify bonus parameters
    function verifyBonus(uint _sessionId, uint _stakeId, uint _cityId, uint _buildingId, uint _bonusPercent, uint8 _v, bytes32 _r, bytes32 _s) internal returns(bool) {  

        bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
        bytes32 message         = keccak256(abi.encodePacked(_stakeId, _sessionId, _cityId, _buildingId, _bonusPercent));
        bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        address recover         = ecrecover(hash, _v, _r, _s);

        require(recover == owner(), "Verification failed");
        return true;

    }

    function _claim(bytes32 key, address stakerAddr, uint interest) internal override returns(bool) {
        uint _stakeId = keyToId[key];
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        IERC20(tokenStaking.rewardToken).safeTransfer(stakerAddr, interest);

        return true;
    }  


    //////////////////////////////////////////////////////////////////////////
    //
    // Helpers
    //
    //////////////////////////////////////////////////////////////////////////

    function stakeKeyOf(uint _sessionId, uint _stakeId) public virtual returns(bytes32) {
        return keccak256(abi.encodePacked(_sessionId, _stakeId));
    }

    /// @dev Moonscape Game can have one season live ot once.
    function validSessionTime(uint _startTime, uint _endTime) public view returns(bool) {
        Session storage session = sessions[sessionId];

        if (_startTime > session.endTime && _startTime >= block.timestamp && _startTime < _endTime) {
            return true;
        }

        return false;
    }

     /// @dev session.startTime <= current time <= session.endTime
    function isActive(uint256 _sessionId) internal view returns(bool) {
        if (_sessionId == 0) {
            return false;
        }
        return (block.timestamp >= sessions[_sessionId].startTime && block.timestamp <= sessions[_sessionId]
            .endTime);
    }
    
    /// @dev allow transfer native token in to the contract as reward token
    receive() external payable {
        // React to receiving ether
    }

    /// @dev encrypt token data
    /// @return encrypted data
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}