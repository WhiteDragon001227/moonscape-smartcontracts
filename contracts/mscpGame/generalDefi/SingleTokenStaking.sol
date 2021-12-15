pragma solidity 0.6.7;

import "./../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../../openzeppelin/contracts/access/Ownable.sol";
import "./../../openzeppelin/contracts/math/SafeMath.sol";
import "./../../openzeppelin/contracts/utils/Counters.sol";

/// @title lp staking
/// @author Nejc Schneider
/// @notice contract is a modified version of
contract SingleTokenStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    uint256 private constant scaler = 10**18;

    Counters.Counter private sessionId;

    /// @notice game event struct. as event is a solidity keyword, we call them session instead.
    struct Session {
		address rewardToken;		// token to be received by user, as a reward for staking
		address stakingToken;  		// token to be staked by user, in order to receive rewardToken
        uint256 totalReward;   		// amount of reward tokens to airdrop
        uint256 startTime;     		// session start timestamp
		uint256 period;        		// session duration in seconds
		uint256 claimed;       		// amount of rewardToken already claimed by users
		uint256 amount;        		// total amount of staked tokens by users
		uint256 rewardUnit;    		// reward per second = totalReward/period (aka TPS - Tokens Per Second)
		uint256 interestPerToken; 	// total earned interest per token since the session start
		uint256 claimedPerToken;    // total amount of tokens earned by a staked token ince the session start
		uint256 lastInterestUpdate; // timestamp of last claimedPerToken or interestPerToken update
	  }

    /// @notice balance of lp token that each player deposited to game session
    struct Balance {
		uint256 amount;        		// current amount of staked token
		uint256 claimed;       		// current amount of claimed reward token
		uint256 claimedTime;        // time of last claim

		uint256 claimedReward;
		uint256 unpaidReward;       // Amount of reward token that contract should pay to user
    }

    /// @dev stakingToken => sessionId
    mapping(address => uint256) public lastSessionIds;
    /// @dev sessionId => Session struct
    mapping(uint256 => Session) public sessions;
    /// @dev sessionId => userAddress => Balance struct
    mapping(uint256 => mapping(address => Balance)) public balances;
    /// @dev TODO add and verify
    mapping(uint256 => mapping(address => uint)) public depositTimes;

    event SessionStarted(
        address indexed rewardToken,
        address indexed stakingToken,
        uint256 indexed sessionId,
        uint256 reward,
        uint256 startTime,
        uint256 endTime
    );

    event Deposited(
        address indexed stakingToken,
        address indexed owner,
        uint256 sessionId,
        uint256 amount,
        uint256 startTime,
        uint256 totalStaked
    );

    event Claimed(
        address indexed stakingToken,
        address indexed owner,
        uint256 sessionId,
        uint256 amount,
        uint256 claimedTime
    );

    event Withdrawn(
        address indexed stakingToken,
        address indexed owner,
        uint256 sessionId,
        uint256 amount,
        uint256 startTime,
        uint256 totalStaked
    );

    /// @dev CWS is not changable after contract deployment.
    constructor() public {
        sessionId.increment();
    }

    //--------------------------------------------------
    // Only owner
    //--------------------------------------------------

    /// @notice Starts a staking session for a finit _period of
    /// time, starting from _startTime. The _totalReward of
    /// Reward tokens will be distributed in every second.
    function startSession(
        address _rewardToken,
        address _stakingToken,
        uint256 _totalReward,
        uint256 _period,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        require(_rewardToken != address(0), "invalid reward token address");
    	require(_stakingToken != address(0), "invalid staking token address");
        require(_totalReward > 0, "total reward should be above 0");
        require(_period > 0, "period should be above 0");
    	require(_startTime > block.timestamp, "seassion should start in the future");
        // @dev reward tokens must be deposited to contract before starting session
        require(IERC20(_rewardToken).balanceOf(address(this)) >= _totalReward,
            "insufficient reward token contract balance");
		// if game session for the staked token was already created, it must be finished
		uint256 _lastId = lastSessionIds[_stakingToken];
		if (_lastId > 0) {
			require(!isActive(_lastId), "last session is still active");
		}

		// update data
		uint256 _sessionId = sessionId.current();
		uint256 _rewardUnit = _totalReward.div(_period);
		sessions[_sessionId] = Session(_rewardToken, _stakingToken, _totalReward, _startTime,
        _period, 0, 0, _rewardUnit, 0, 0, 0);
		sessionId.increment();
		lastSessionIds[_stakingToken] = _sessionId;

		emit SessionStarted(
            _rewardToken,
            _stakingToken,
            _sessionId,
            _totalReward,
            _startTime,
            _startTime + _period
        );
    }

    /// TODO rename this function to claim
  function payDebt(uint256 _sessionId, address _address) external onlyOwner {
      Balance storage _balance = balances[_sessionId][_address];
      require(_balance.unpaidReward > 0, "no debt do collect");
      IERC20 _reward = IERC20(sessions[_sessionId].rewardToken);
      uint256 _contractBalance = _reward.balanceOf(address(this));
      require(_contractBalance >= _balance.unpaidReward,
          "insufficient reward token contract balance");

      _balance.unpaidReward = 0;

      _reward.safeTransfer(_address, _balance.unpaidReward);
  }

    //--------------------------------------------------
    // Only game users
    //--------------------------------------------------

    /// @notice deposits _amount of LP token
    function deposit(uint256 _sessionId, uint256 _amount) external {
        require(_amount > 0, "invalid deposit amount");
        require(_sessionId > 0, "invalid sessionId");
        require(isActive(_sessionId), "session is not active");

        updateInterestPerToken(_sessionId);

        IERC20 _token = IERC20(sessions[_sessionId].stakingToken);

        require(_token.balanceOf(msg.sender) >= _amount, "not enough tokens to deposit");
        require(_token.transferFrom(msg.sender, address(this), _amount),
            "transfer of tokens to contract failed");

        Session storage _session  = sessions[_sessionId];
        Balance storage _balance  = balances[_sessionId][msg.sender];

        // claim tokens if any
        if (_balance.amount > 0) {
            _claim(_sessionId);
        }

        _session.amount = _session.amount.add(_amount); // 10

        // NOTE interest per token is updated. maybe need to withdraw out?
        updateInterestPerToken(_sessionId);

        _balance.amount = _amount.add(_balance.amount);
        _balance.claimedTime = block.timestamp;

        depositTimes[_sessionId][msg.sender] = block.timestamp;

        updateBalanceInterestPerToken(_sessionId, msg.sender);

        emit Deposited(
            _session.stakingToken,
            msg.sender,
            _sessionId,
            _amount,
            block.timestamp,
            _session.amount
        );
    }

    ///TODO remove _claim function and unify
    function claim(uint256 _sessionId) public returns(bool) {
        require(balances[_sessionId][msg.sender].amount > 0, "no tokens to withdraw");
        updateInterestPerToken(_sessionId);

        _claim(_sessionId);
        updateBalanceInterestPerToken(_sessionId, msg.sender);

        return true;
    }

    /// @notice Withdraws _amount of LP token
    /// of type _token out of Staking contract.
    function withdraw(uint256 _sessionId, uint256 _amount) external {
        Session storage _session = sessions[_sessionId];
        Balance storage _balance  = balances[_sessionId][msg.sender];

        require(_balance.amount >= _amount, "amount exceeds user allocation");

        updateInterestPerToken(_sessionId);

        IERC20 _token = IERC20(_session.stakingToken);
        require(_token.balanceOf(address(this)) >= _amount, "insufficient contract balance");
        uint256 _interest = calculateInterest(_sessionId, msg.sender);

        IERC20 _reward = IERC20(_session.rewardToken);
        uint256 _contractBalance = _reward.balanceOf(address(this));

        if (_interest > 0 && _contractBalance < _interest) {
            _balance.unpaidReward = _interest.sub(_contractBalance).add(_balance.unpaidReward);
        }

        _balance.amount = _balance.amount.sub(_amount);
        _session.amount = _session.amount.sub(_amount);

        if (_interest > 0) {
            _session.claimed = _session.claimed.add(_interest);
            _balance.claimed = _balance.claimed.add(_interest);
            if (!isActive(_sessionId)) {
                _balance.claimedTime = _session.startTime.add(_session.period);
            } else {
                _balance.claimedTime = block.timestamp;
            }

            _reward.safeTransfer(msg.sender, _interest);
            emit Claimed(
                _session.stakingToken,
                msg.sender,
                _sessionId,
                _interest,
                block.timestamp
            );
        }
        require(_token.transfer(msg.sender, _amount),
            "Failed to transfer token from contract to user");

        // update session.interestPerToken
        updateInterestPerToken(_sessionId);
        updateBalanceInterestPerToken(_sessionId, msg.sender);

        emit Withdrawn(
            sessions[_sessionId].stakingToken,
            msg.sender,
            _sessionId,
            _amount,
            block.timestamp,
            sessions[_sessionId].amount
        );
    }

    //--------------------------------------------------
    // Public methods
    //--------------------------------------------------

    /// @notice Returns amount of Token staked by _owner
    function stakedBalanceOf(uint256 _sessionId, address _owner) external view returns(uint256) {
        return balances[_sessionId][_owner].amount;
    }

    /// @notice Returns amount of CWS Tokens earned by _address
    function earned(uint256 _sessionId, address _owner) external view returns(uint256) {
        uint256 _interest = calculateInterest(_sessionId, _owner);
        return balances[_sessionId][_owner].claimed.add(_interest);
    }

    /// @notice Returns amount of CWS Tokens that _address could claim.
    function claimable(uint256 _sessionId, address _owner) external view returns(uint256) {
        return calculateInterest(_sessionId, _owner);
    }

    /// @notice Returns total amount of Staked LP Tokens
    function stakedBalance(uint256 _sessionId) external view returns(uint256) {
        return sessions[_sessionId].amount;
    }

    //---------------------------------------------------
    // Internal methods
    //---------------------------------------------------

    /// @dev check whether the session is active or not
    function isActive(uint256 _sessionId) internal view returns(bool) {
        uint256 _endTime = sessions[_sessionId].startTime.add(sessions[_sessionId].period);

        // _endTime will be 0 if session never started.
        if (now < sessions[_sessionId].startTime || now > _endTime)
            return false;
        return true;
    }

    function calculateInterest(uint256 _sessionId, address _owner) internal view returns(uint256) {
        Session storage _session = sessions[_sessionId];
        Balance storage _balance = balances[_sessionId][_owner];

        // How much of total deposit is belong to player as a floating number
        if (_balance.amount == 0 || _session.amount == 0)
            return 0;

        uint256 _sessionCap = block.timestamp;
        if (!isActive(_sessionId)) {
            _sessionCap = _session.startTime.add(_session.period);

            // claimed after session expire, means no any claimables
            if (_balance.claimedTime >= _sessionCap)
                return 0;
        }

        uint256 claimedPerToken = _session.claimedPerToken.add(_sessionCap
            .sub(_session.lastInterestUpdate).mul(_session.interestPerToken));

        // (balance * total claimable) - user deposit earned amount per token - balance.claimedTime
        uint256 _interest = _balance.amount.mul(claimedPerToken)
            .div(scaler).sub(_balance.claimedReward);

        return _interest;
    }


    /// @dev updateInterestPerToken set's up the amount of tokens earned since the beginning
    /// of the session to 1 token. It also updates the portion of it for the user.
    /// @param _sessionId is a session id
    function updateInterestPerToken(uint256 _sessionId) internal returns(bool) {
        Session storage _session = sessions[_sessionId];

        uint256 _sessionCap = block.timestamp;
        if (!isActive(_sessionId)) {
            _sessionCap = _session.startTime.add(_session.period);
        }

        // Calculate previous claimed rewards
        // (session.claimedPerToken += (now - session.lastInterestUpdate) * session.interestPerToken)
        _session.claimedPerToken = _session.claimedPerToken.add(_sessionCap
            .sub(_session.lastInterestUpdate).mul(_session.interestPerToken));

        // Record that interestPerToken is 0.1 CWS (rewardUnit/amount) in session.interestPerToken
        // Update the session.lastInterestUpdate to now
        if (_session.amount == 0) {
            _session.interestPerToken = 0;
        } else {
            _session.interestPerToken = _session.rewardUnit.mul(scaler).div(_session.amount); // 0.1
        }

        // we avoid sub. underflow, for calulating session.claimedPerToken
        _session.lastInterestUpdate = _sessionCap;
    }

    function updateBalanceInterestPerToken(
        uint256 _sessionId,
        address _owner
    )
        internal
        returns(bool)
    {
        Session storage _session = sessions[_sessionId];
        Balance storage _balance = balances[_sessionId][_owner];

        // also, need to attach to alex,
        // that previous earning (session.claimedPerToken) is 0.
        _balance.claimedReward = _session.claimedPerToken.mul(_balance.amount).div(scaler); // 0
    }

    function _claim(uint256 _sessionId) internal returns(bool) {
        Session storage _session = sessions[_sessionId];
        Balance storage _balance = balances[_sessionId][msg.sender];

        require(_balance.amount > 0, "No deposit was found");

        uint256 _interest = calculateInterest(_sessionId, msg.sender);
        if (_interest == 0)
            return false;
        IERC20 _reward = IERC20(sessions[_sessionId].rewardToken);
        uint256 _contractBalance = _reward.balanceOf(address(this));
        if (_interest > 0 && _contractBalance < _interest)
            _balance.unpaidReward = _interest.sub(_contractBalance).add(_balance.unpaidReward);

        // we avoid sub. underflow, for calulating session.claimedPerToken
        if (!isActive(_sessionId)) {
            _balance.claimedTime = _session.startTime.add(_session.period);
        } else {
            _balance.claimedTime = block.timestamp;
        }
        _session.claimed     = _session.claimed.add(_interest);
        _balance.claimed     = _balance.claimed.add(_interest);

        _reward.safeTransfer(msg.sender, _interest);

        emit Claimed(_session.stakingToken, msg.sender, _sessionId, _interest, block.timestamp);
        return true;
    }

}
