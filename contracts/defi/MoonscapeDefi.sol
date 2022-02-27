pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Stake.sol";

contract MoonscapeDefi is Stake {
    using SafeERC20 for IERC20;

    uint public sessionId;
    uint public stakeId;

    struct Session {
        uint startTime;
        uint endTime;
        bool active;
    }

    struct TokenStaking {
        uint sessionId;
        address stakeToken;
        uint rewardPool;
        address rewardToken;
    }

    mapping(uint => Session) public sessions;
    mapping(bytes32 => bool) public addedStakings;
    mapping(uint => TokenStaking) public tokenStakings;

    event StartSession(uint indexed sessionId, uint startTime, uint endTime);
    event PauseSession(uint indexed sessionId);
    event ResumeSession(uint indexed sessionId);
    event AddStaking(uint indexed sessionId, uint indexed stakeId);

    constructor () public {}

    // start session
    function startSession(uint _startTime, uint _endTime) external {
        require(validSessionTime(_startTime, _endTime), "INVALID_SESSION_TIME");

        sessionId++;

        sessions[sessionId] = Session(_startTime, _endTime, true);

        emit StartSession(sessionId, _startTime, _endTime);
    }
    // pause session
    function pauseSession(uint _sessionId) external {
        Session storage session = sessions[_sessionId];

        require(session.active, "INACTIVE");

        session.active = false;

        emit PauseSession(_sessionId);
    }

    function resumeSession(uint _sessionId) external {
        Session storage session = sessions[_sessionId];

        require(session.endTime > 0 && !session.active, "ACTIVE");

        session.active = true;

        emit ResumeSession(_sessionId);
    }

    function addTokenStaking(uint _sessionId, address stakeAddress, uint rewardPool, address rewardToken) external {
        bytes32 key = keccak256(abi.encodePacked(_sessionId, stakeAddress, rewardToken));

        require(!addedStakings[key], "DUPLICATE_STAKING");

        addedStakings[key] = true;

        tokenStakings[++stakeId] = TokenStaking(_sessionId, stakeAddress, rewardPool, rewardToken);

        emit AddStaking(_sessionId, stakeId);
    }

    // stake
    function stakeToken(uint _stakeId, uint _cityId, uint _buildingId, uint _amount, uint8 v, bytes32[2] calldata sig) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // todo
        // validate the session id

        deposit(_stakeId, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);

        uint preBalance = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        _amount = token.balanceOf(address(this)) - preBalance;
    }

    function unstakeToken(uint _stakeId, uint _amount) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // todo
        // validate the session id

        withdraw(_stakeId, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);

        uint preBalance = token.balanceOf(address(this));

        token.safeTransfer(msg.sender, _amount);

        _amount = token.balanceOf(address(this)) - preBalance;
    }

    function claim(uint _stakeId)
        external
        returns(uint256)
    {
        return reward(_stakeId, msg.sender);
    }

    function _claim(uint key, address stakerAddr, uint interest) internal override returns(bool) {
        address rewardToken =  tokenStakings[key].rewardToken;
        
        IERC20(rewardToken).safeTransfer(stakerAddr, interest);

        return true;
    }  

    // unstake

    //////////////////////////////////////////////////////////////////////////
    //
    // Helpers
    //
    //////////////////////////////////////////////////////////////////////////

    /**
     * Moonscape Game can have one season live ot once.
     */
    function validSessionTime(uint _startTime, uint _endTime) public view returns(bool) {
        Session storage session = sessions[sessionId];

        if (_startTime > session.endTime && _startTime >= block.timestamp && _startTime < _endTime) {
            return true;
        }

        return false;
    }
}