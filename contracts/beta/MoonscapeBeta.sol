pragma solidity 0.6.7;

import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/// @author Nejc Schneider
/// Users lock 100k mscp during session, and can unlock it after its finished
contract MoonscapeBeta is Ownable{
    using SafeERC20 for IERC20;

    uint public sessionId;

    struct Session {
        uint startTime; // session start time
        uint endTime;   // session end time
        uint requiredAmount;    // unlock game need token amonut
        IERC20 token;   //token address
    }

    mapping(uint => mapping(address => bool)) public stakers;
    mapping(uint => Session) public sessions;

    event Transfer(address sender, bool locked);
    event StartSession(uint sessionId, IERC20 token,uint requiredAmount, uint startTime, uint endTime);

    constructor() public {}

    function startSession(IERC20 _token,uint _requiredAmount, uint _startTime, uint _endTime) external onlyOwner{
        require(address(_token) != address(0), "invalid currency address");
        require(_startTime > now, "session should start in future");
        require(_endTime > _startTime, "start time should precede end");
        require(_requiredAmount > 0, "token number wrong");

        sessionId++;

        sessions[sessionId] = Session(_startTime, _endTime, _requiredAmount, _token);

        emit StartSession(sessionId, _token, _requiredAmount, _startTime, _endTime);
    }

    function lock(uint _sessionId) external {
        Session storage session = sessions[_sessionId];
        require(session.startTime < now, "session hasnt started yet");
        require(session.endTime > now, "session is finished");
        require(!stakers[_sessionId][msg.sender], "tokens already locked");
        require(session.requiredAmount > 0, "token number wrong");
        require(session.token.balanceOf(msg.sender) >= session.requiredAmount, "insufficient mscp user balance");

        stakers[_sessionId][msg.sender] = true;

        session.token.safeTransferFrom(msg.sender, address(this), session.requiredAmount);

        emit Transfer(msg.sender, true);
    }

    function unlock(uint _sessionId) external{
        Session storage session = sessions[_sessionId];
        require(now > session.endTime);
        require(stakers[_sessionId][msg.sender], "no tokens locked");
        require(session.requiredAmount > 0, "token number wrong");

        stakers[_sessionId][msg.sender] = false;

        session.token.safeTransfer(msg.sender, session.requiredAmount);

        emit Transfer(msg.sender, false);
    }
}
