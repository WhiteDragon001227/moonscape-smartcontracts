// Seascape NFT
// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/// @author Nejc Schneider
contract MoonscapeBeta {
    using SafeERC20 for IERC20;

    uint public startTime;
    uint public endTime;

    mapping(address => bool) public stakers;

    /// NOTE may not be needed, move to constructor
    constructor(uint _startTime, uint _endTime) public {
        require(_startTime > now, "session should start in future");
        require(_endTime > _startTime, "start time should precede end");
        startTime = _startTime;
        endTime = _endTime;
    }

    function Lock() external {
        require(startTime > now, "session hasnt started yet");
        require(endTime < now, "session is finished");
        // require msg.sender has 100k MSCP

        // make sure tokens are transfered

        // save user address to mapping as true

        // emit event with msg.sender address
    }

    function Unlock() external{
        require(now > endTime);
        // require msg.sender address has locked tokens

        // set user address in mapping to false

        // emit event

    }
}
