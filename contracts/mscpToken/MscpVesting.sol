pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";

/// @title Vesting Contract for moonscape (MSCP) token.
/// @author Nejc Schneider
/// @notice Unlock tokens for pre-approved addresses gradualy over time.
contract MscpVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev session data
    IERC20 private immutable token;
  	uint256 public startTime;
    /// @dev total tokens to be released gradualy (excluding "day one" tokens)
    uint256 constant private SUPPLY_PRIVATE = 8500000 * 10**18;
    uint256 constant private SUPPLY_STRATEGIC = 8000000 * 10**18;
    /// @dev vesting duration in seconds
    uint256 constant private DURATION_PRIVATE =  25920000;    /// 300 days
    uint256 constant private DURATION_STRATEGIC = 12960000;   /// 150 days

    struct Balance {
        uint256 remainingCoins;
    	  bool strategicInvestor;   // true if investor type is strategic
        bool claimedBonus;        // true if "day one" tokens were claimed
    }

    mapping(address=>Balance) public balances;

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
    /// @param _strategicInvestor true if strategic investor
    function addInvestor (address _investor, bool _strategicInvestor) external onlyOwner {
        require(balances[_investor].remainingCoins == 0, "investor already has allocation");
        require(balances[_investor].claimedBonus)

        if(_strategicInvestor){
            balances[_investor].remainingCoins = SUPPLY_STRATEGIC;
            balances[_investor].strategicInvestor = true;
        } else
            balances[_investor].remainingCoins = SUPPLY_PRIVATE;

        emit InvestorModified(_investor, balances[_investor].remainingCoins);
    }

    /// @notice set investor remaining coins to 0
    /// @param _investor address to disable
    function disableInvestor (address _investor) external onlyOwner {
        require(balances[_investor].remainingCoins > 0, "investor already disabled");
        balances[_investor].remainingCoins = 0;
        emit InvestorModified(_investor, balances[_investor].remainingCoins);
    }

    /// @notice clam the unlocked tokens
    function withdraw () external {
        Balance storage balance = balances[msg.sender];
        require(now >= startTime, "vesting hasnt started yet");
        require(balance.remainingCoins > 0, "user has no allocation");

        uint256 timePassed = getDuration(balance.strategicInvestor);
        uint256 availableAmount = getAvailableTokens(balance
            .strategicInvestor, timePassed, balance.remainingCoins);

        balance.remainingCoins = balance.remainingCoins.sub(availableAmount);
        if(!balance.claimedBonus){  // @dev bonus should not be substracted from remaining coins
            balance.claimedBonus = true;
            availableAmount += getBonus(balance.strategicInvestor);
        }

        token.safeTransfer(msg.sender, availableAmount);

        emit Withdraw(msg.sender, availableAmount, balance.remainingCoins);
    }

    //--------------------------------------------------------------------
    //  internal functions
    //--------------------------------------------------------------------

    /// @dev calculate how much time has passed since start.
    /// If vesting is finished, return length of the session
    /// @param _strategicInvestor true if strategic investor
    /// @return duration of time in seconds
    function getDuration(bool _strategicInvestor) internal view returns(uint) {
        if(_strategicInvestor){
            if(now < startTime + DURATION_STRATEGIC)
                return now - startTime;
            return DURATION_STRATEGIC;
        } else {
            if(now < startTime + DURATION_PRIVATE)
                return now - startTime;
            return DURATION_PRIVATE;
        }
    }

    /// @dev calculate how many tokens are available for withdrawal
    /// @param _strategicInvestor true if strategic investor
    /// @param _timePassed amount of time since vesting started
    /// @param _remainingCoins amount of unspent tokens
    /// @return tokens amount
    function getAvailableTokens(
        bool _strategicInvestor,
        uint256 _timePassed,
        uint256 _remainingCoins
    )
        internal
        view
        returns(uint)
    {
        if(_strategicInvestor){
            uint256 unclaimedPotential = (_timePassed * SUPPLY_STRATEGIC / DURATION_STRATEGIC);
            return unclaimedPotential - (SUPPLY_STRATEGIC - _remainingCoins);
        } else {
            uint256 unclaimedPotential = (_timePassed * SUPPLY_PRIVATE / DURATION_PRIVATE);
            return unclaimedPotential - (SUPPLY_PRIVATE - _remainingCoins);
        }
    }

    /// @dev calculate bonus based on investor type
    /// @param _strategicInvestor true if strategic investor
    /// @return bonus amount
    function getBonus(bool _strategicInvestor) internal view returns(uint) {
        if(_strategicInvestor)
            return 2000000 * 10**18; // 2 mil is released on day one
        return 1500000 * 10**18; // 1.5 mil is released on day one
    }
}
