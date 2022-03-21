pragma solidity 0.6.7;

import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Stake.sol";

contract MoonscapeDefi is Stake, IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    address private constant dead = 0x000000000000000000000000000000000000dEaD;

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
        bool burn;
    }

    struct Player {
        uint nftId;                 //stake scape nftid
        uint power;
        uint claimedAmound;         //received rewards
        bool receiveBonus;          //Whether to receive rewards about bonus
    }

    mapping(uint => Session) public sessions;
    mapping(bytes32 => bool) public addedStakings;
    mapping(uint => TokenStaking) public tokenStakings;         //uint stakeId => TokenStaking
    mapping(bytes32 => uint) public keyToId;                    //bytes32 key(stakeKeyOf(sessionId,stakeId)  => stakeId
    mapping(bytes32 => mapping(address => Player)) public playerParams; //bytes32 key(stakeKeyOf(sessionId,stakeId)=> weallet address => player

    event StartSession(uint indexed sessionId, uint startTime, uint endTime);
    event PauseSession(uint indexed sessionId);
    event ResumeSession(uint indexed sessionId);
    event AddStaking(uint indexed sessionId, uint indexed stakeId);
    event StakeToken(address indexed staker, uint indexed sessionId, uint stakeId, uint cityId, uint buildingId, uint indexed amount);
    event UnStakeToken(address indexed staker, uint indexed sessionId, uint stakeId, uint indexed amount);
    event StakeNft(address indexed staker, uint indexed sessionId, uint stakeId, uint cityId, uint buildingId, uint indexed scapeNftId, uint power);
    event UnStakeNft(address indexed staker, uint indexed sessionId, uint stakeId, uint indexed scapeNftId, uint power);

    constructor () public {}

    /// @dev start a new session
    function startSession(uint _startTime, uint _endTime) external onlyOwner{
        require(validSessionTime(_startTime, _endTime), "INVALID_SESSION_TIME");

        sessionId++;

        sessions[sessionId] = Session(_startTime, _endTime, true);

        emit StartSession(sessionId, _startTime, _endTime);
    }

    /// @dev pause session
    function pauseSession(uint _sessionId) external onlyOwner{
        Session storage session = sessions[_sessionId];

        require(session.active, "INACTIVE");

        session.active = false;

        emit PauseSession(_sessionId);
    }

    /// @dev resume session, make it active
    function resumeSession(uint _sessionId) external onlyOwner{
        Session storage session = sessions[_sessionId];

        require(session.endTime > 0 && !session.active, "ACTIVE");

        session.active = true;

        emit ResumeSession(_sessionId);
    }

    /// @dev add token staking to session
    function addTokenStaking(uint _sessionId, address stakeAddress, uint rewardPool, address rewardToken, uint _burn) external onlyOwner{
        bytes32 key = keccak256(abi.encodePacked(_sessionId, stakeAddress, rewardToken));

        require(!addedStakings[key], "DUPLICATE_STAKING");

        addedStakings[key] = true;
        bool burn = true;

        if (_burn == 1) {
            burn = true;
        } else {
            burn = false;
        }

        tokenStakings[++stakeId] = TokenStaking(_sessionId, stakeAddress, rewardPool, rewardToken, burn);

        bytes32 stakeKey = stakeKeyOf(sessionId, stakeId);

        keyToId[stakeKey] = stakeId;

        Session memory session = sessions[_sessionId];

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
        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        require(isActive(stakeKey), "session not active");

        //validate stake id
        require(_stakeId <= stakeId,"do not have this stakeId");

        {
        bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
        bytes32 message         = keccak256(abi.encodePacked(_stakeId, tokenStaking.sessionId, _cityId, _buildingId));
        bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        address recover         = ecrecover(hash, v, sig[0], sig[1]);

        require(recover == owner(), "Verification failed about stakeToken");
        }

        deposit(stakeKey, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);

        require(token.balanceOf(msg.sender) >= _amount, "Not enough token to stake");
        // uint preBalance = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);
        // _amount = token.balanceOf(address(this)) - preBalance;
        emit StakeToken(msg.sender, tokenStaking.sessionId, _stakeId, _cityId, _buildingId, _amount);
    }

    /// @dev withdraw tokens
    function unstakeToken(uint _sessionId, uint _stakeId, uint _amount) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // todo
        // validate the session id

        bytes32 stakeKey = stakeKeyOf(_sessionId, _stakeId);

        withdraw(stakeKey, msg.sender, _amount);

        IERC20 token = IERC20(tokenStaking.stakeToken);
        // uint preBalance = token.balanceOf(address(this));

        token.safeTransfer(msg.sender, _amount);
        // _amount = token.balanceOf(address(this)) - preBalance;
        emit UnStakeToken(msg.sender, _sessionId, _stakeId, _amount);
    }

    /// @dev stake nft
    function stakeNft(uint _stakeId, uint _cityId, uint _buildingId, uint _scapeNftId, uint _power, uint8 _v, bytes32[2] calldata sig) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        // validate the session id
        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        Player storage player = playerParams[stakeKey][msg.sender];

        require(player.nftId <= 0 && player.power <= 0, "already stake nft");

        require(isActive(stakeKey), "session not active");

        //validate stake id
        require(_stakeId <= stakeId,"do not have this stakeId");

        IERC721 nft = IERC721(tokenStaking.stakeToken);
        require(nft.ownerOf(_scapeNftId) == msg.sender, "not owned");

        {
        bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
        bytes32 message         = keccak256(abi.encodePacked(tokenStaking.sessionId, _stakeId, _cityId, _buildingId, _scapeNftId, _power));
        bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        address recover         = ecrecover(hash, _v, sig[0], sig[1]);

        require(recover == owner(), "Verification failed about stakeNft");
        }

        nft.safeTransferFrom(msg.sender, address(this), _scapeNftId);

        deposit(stakeKey, msg.sender, _power);

        player.nftId = _scapeNftId;
        player.power = _power;

        emit StakeNft(msg.sender, tokenStaking.sessionId, _stakeId, _cityId, _buildingId, _scapeNftId, _power);
    }

    /// @dev unstake nft
    function unstakeNft(uint _sessionId, uint _stakeId, uint _scapeNftId) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];
        bytes32 stakeKey = stakeKeyOf(_sessionId, _stakeId);

        Player storage player = playerParams[stakeKey][msg.sender];

        require(player.nftId > 0 && player.power > 0, "don't stake nft");

        IERC721 nft = IERC721(tokenStaking.stakeToken);

        if (tokenStaking.burn) {
            nft.safeTransferFrom(address(this), dead, _scapeNftId);
        } else {
            nft.safeTransferFrom(address(this), msg.sender, _scapeNftId);
        }

        withdraw(stakeKey, msg.sender, player.power);

        emit UnStakeNft(msg.sender, _sessionId, _stakeId, _scapeNftId, player.power);

        delete player.nftId;
        delete player.power;
    }

    /// @dev claim rewards
    function claim(uint _sessionId, uint _stakeId)
        external
        returns(uint256)
    {
        bytes32 stakeKey = stakeKeyOf(_sessionId, _stakeId);

        require(isActive(stakeKey), "session is ended, only unstake");

        return reward(stakeKey, msg.sender);
    }

    /// @dev get bonus reward after session is ended
    function getBonus(uint _stakeId, uint _cityId, uint _buildingId, uint _bonusPercent, uint8 _v, bytes32[2] calldata sig) external {
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];
        Session storage session = sessions[tokenStaking.sessionId];
        bytes32 stakeKey = stakeKeyOf(tokenStaking.sessionId, _stakeId);

        require(block.timestamp > session.endTime, "it has to be after the session");

        Player storage player = playerParams[stakeKey][msg.sender];

        require(player.receiveBonus == true, "already rewarded");

        {
        bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
        bytes32 message         = keccak256(abi.encodePacked(_stakeId, tokenStaking.sessionId, _cityId, _buildingId, _bonusPercent));
        bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        address recover         = ecrecover(hash, _v, sig[0], sig[1]);

        require(recover == owner(), "Verification failed about getBonus");
        }

        uint256 _totalreward = claimable(stakeKey, msg.sender) + player.claimedAmound;
        uint256 _totalBonus  = _totalreward.mul(scaler).mul(_bonusPercent).div(100).div(scaler);

        require(_totalBonus > 0, "totalBonus must > 0");
        _safeTransfer(tokenStaking.rewardToken, msg.sender, _totalBonus);

        player.receiveBonus = true;
    }

    function _claim(bytes32 key, address stakerAddr, uint interest) internal override returns(bool) {
        uint _stakeId = keyToId[key];
        TokenStaking storage tokenStaking = tokenStakings[_stakeId];

        _safeTransfer(tokenStaking.rewardToken, stakerAddr, interest);

        //for bonus
        Player storage player = playerParams[key][stakerAddr];
        player.claimedAmound += claimable(key, stakerAddr);

        return true;
    }  


    function _safeTransfer(address _token, address _to, uint256 _amount) internal {
        if (_token != address(0)) {
            IERC20 _rewardToken = IERC20(_token);

            uint256 _balance = _rewardToken.balanceOf(address(this));
            require(_amount <= _balance, "do not have enough token to reward");
            _rewardToken.transfer(_to, _amount);
        } else {

            uint256 _balance = address(this).balance;
            require(_amount <= _balance, "do not have enough token to reward");
            payable(_to).transfer(_amount);
        }
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
        Session memory session = sessions[sessionId];

        if (_startTime > session.endTime && _startTime >= block.timestamp && _startTime < _endTime) {
            return true;
        }

        return false;
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