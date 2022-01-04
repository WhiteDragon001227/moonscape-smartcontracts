pragma solidity 0.6.7;

import "./../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../../openzeppelin/contracts/access/Ownable.sol";
import "./../../openzeppelin/contracts/math/SafeMath.sol";

contract MscpToMoondust is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    address MSCP;

    struct Balance {
		uint256 totalSpent;      	// total amount of spend mscp
		uint256 stakeAmount;        // current amount of staked mscp
    }

    /// @dev userAddress => Balance struct
    mapping(address => Balance) public balances;

    event Spent(
        address indexed spender,
        uint256 amount,
        uint256 spentTime,
        uint256 totalSpent
    );

    event Stake(
        address indexed staker,
        uint256 amount,
        uint256 stakeTime,
        uint256 stakeAmount
    );

    event Unstake(
        address indexed staker,
        uint256 amount,
        uint256 unstakeTime,
        uint256 stakeAmount
    );

    constructor(address _mscpToken) public {
        MSCP = _mscpToken;
    }

    function spend(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(msg.sender) >= _amount, "not enough tokens to deposit");
        require(_token.transferFrom(msg.sender, address(this), _amount), "transfer of tokens to contract failed");

        Balance storage _balance  = balances[msg.sender];
        _balance.totalSpent = _amount.add(_balance.totalSpent);

        emit Spent(msg.sender, _amount, block.timestamp, _balance.totalSpent);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(msg.sender) >= _amount, "not enough tokens to deposit");
        require(_token.transferFrom(msg.sender, address(this), _amount), "transfer of tokens to contract failed");

        Balance storage _balance  = balances[msg.sender];
        _balance.stakeAmount = _amount.add(_balance.stakeAmount);

        emit Stake(msg.sender, _amount, block.timestamp, _balance.stakeAmount);
    }

    function unstake(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        Balance storage _balance  = balances[msg.sender];
        require(_amount <= _balance.stakeAmount, "can't unstake more than staked");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(address(this)) >= _amount, "insufficient contract balance");

        require(_token.transfer(msg.sender, _amount), "Failed to transfer token from contract to user");

        _balance.stakeAmount = _balance.stakeAmount.sub(_amount);

        emit Unstake(msg.sender, _amount, block.timestamp, _balance.stakeAmount);
    }

}