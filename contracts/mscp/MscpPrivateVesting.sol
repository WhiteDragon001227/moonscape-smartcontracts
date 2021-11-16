pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";

/// @title Vesting Contract for moonscape (MSCP) token.
/// @author Nejc Schneider
/// @notice Unlock tokens for pre-approved addresses gradualy over time.
contract MscpPrivateVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev session data
    IERC20 private immutable token;
  	uint256 public startTime;
    /// @dev total tokens to be released gradualy (excluding "day one" tokens)
    uint256 constant private SUPPLY = 4250000 * 10**18;
    uint256 constant private DURATION =  25920000;     /// 300 days

    /// @dev investorAddress => remainingCoins
    mapping(address=>uint) public remainingCoins;
    mapping(address=>bool) public bonusGiven;

    event InvestorModified(address indexed investor, uint256 remainingCoins);
    event Withdraw(address indexed receiver, uint256 withdrawnAmount, uint256 remainingCoins);

    constructor (IERC20 _token, uint256 _startTime) public {
        require(address(_token) != address(0), "invalid currency address");
        require(_startTime > now, "vesting should start in future");

        token = _token;
        startTime = _startTime;
    }

    //--------------------------------------------------------------------
    //  external functions
    //--------------------------------------------------------------------

    /// @notice add strategic investor address
    /// @param _investor address to be added
    function addInvestor (address _investor) external onlyOwner {
        require(remainingCoins[_investor] == 0, "investor already has allocation");
        remainingCoins[_investor] = SUPPLY;
        emit InvestorModified(_investor, remainingCoins[_investor]);
    }

    /// @notice set investor remaining coins to 0
    /// @param _investor address to disable
    function disableInvestor (address _investor) external onlyOwner {
        require(remainingCoins[_investor] > 0, "investor already disabled");
        remainingCoins[_investor] = 0;
        emit InvestorModified(_investor, remainingCoins[_investor]);
    }

    /// @notice clam the unlocked tokens
    function withdraw () external {
        require(now > startTime, "vesting hasnt started yet");
        require(remainingCoins[msg.sender] > 0, "user has no allocation");

        // getDuration
        uint256 timePassed;
        if(now < startTime + DURATION){
            timePassed = now - startTime;
        } else {
            timePassed = DURATION;
        }
        // getAvailableTokens
        uint256 availableAmount = (timePassed * SUPPLY / DURATION);
        availableAmount = availableAmount - (SUPPLY - remainingCoins[msg.sender]);
        // update balances (and add bonus on first withdrawal)
        remainingCoins[msg.sender] = remainingCoins[msg.sender].sub(availableAmount);
        if(!bonusGiven[msg.sender]){  // @dev bonus should not be substracted from remaining coins
            bonusGiven[msg.sender] = true;
            availableAmount += 750000 * 10**18;
        }

        token.safeTransfer(msg.sender, availableAmount);

        emit Withdraw(msg.sender, availableAmount, remainingCoins[msg.sender]);
    }
}
