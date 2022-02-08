pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/// @author Nejc Schneider
/// Users lock 100k mscp during session, and can unlock it after its finished
contract MoonscapeBeta {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint constant private requiredAmount = 100000 * 10**18;
    uint public startTime;
    uint public endTime;

    mapping(address => bool) public stakers;

    event Transfer(address sender, bool locked);

    constructor(IERC20 _token, uint _startTime, uint _endTime) public {
        require(address(_token) != address(0), "invalid currency address");
        require(_startTime > now, "session should start in future");
        require(_endTime > _startTime, "start time should precede end");

        token = _token;
        startTime = _startTime;
        endTime = _endTime;
    }

    function lock() external {
        require(startTime < now, "session hasnt started yet");
        require(endTime > now, "session is finished");
        require(!stakers[msg.sender], "tokens already locked");
        require(token.balanceOf(msg.sender) >= requiredAmount, "insufficient mscp user balance");

        stakers[msg.sender] = true;

        token.safeTransferFrom(msg.sender, address(this), requiredAmount);

        emit Transfer(msg.sender, true);
    }

    function unlock() external{
        require(now > endTime);
        require(stakers[msg.sender], "no tokens locked");

        stakers[msg.sender] = false;

        token.safeTransfer(msg.sender, requiredAmount);

        emit Transfer(msg.sender, false);
    }
}
