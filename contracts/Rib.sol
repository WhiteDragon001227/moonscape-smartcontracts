// contracts/Crowns.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author Medet Ahmetson
contract Rib is ERC20, Ownable {
    /**
    * @dev Sets the {name} and {symbol} of token.
    * Initializes {decimals} with a default value of 18.
    * Mints all tokens.
    * Transfers ownership to another account. So, the token creator will not be counted as an owner.
    */
    uint256 private supply;

    /// @notice Maximum possible supply of this token.
    uint256 public limitSupply = 1000000000000000000000; /// 1000

    /// @notice Set to false to stop mint/burn of token. Set to true to allow minting.
    bool public bridgeAllowed = false;

    /// @notice the list of bridge addresses allowed to mint tokens.
    mapping(address => bool) public bridges;

    // Mint and Burn
    modifier onlyBridge {
       require(bridgeAllowed && bridges[msg.sender]);
       _;
    }

    event AddBridge(address indexed bridge);
    event RemoveBridge(address indexed bridge);

    constructor() public ERC20("RiverBoat", "RIB") {
        supply = 1000000000000000000000;

        _mint(msg.sender, supply);
    }

    function addBridge(address _bridge) external onlyOwner returns(bool) {
         require(_bridge != address(0), "invalid address");
         require(!bridges[_bridge], "bridge already added");

         bridges[_bridge] = true;

         emit AddBridge(_bridge);
    }

     function removeBridge(address _bridge) external onlyOwner returns(bool) {
        require(_bridge != address(0), "invalid address");
        require(bridges[_bridge], "bridge already removed");

        bridges[_bridge] = false;

        emit RemoveBridge(_bridge);
    }

    function mint(address to, uint256 amount) external onlyBridge {
        require(supply.add(amount) <= limitSupply, "exceeded mint limit");
        _mint(to, amount);
    }

    function toggleBridgeAllowance() external onlyOwner {
        bridgeAllowed = !bridgeAllowed;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Included just to follow the standard of OpenZeppelin.
     */
    function burn(uint256 amount) public {
        require(false, "Only burnFrom is allowed");
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyBridge {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "burn amount exceeds allowance");

        _approve(account, _msgSender(), currentAllowance
            .sub(amount, "transfer amount exceeds allowance"));
        _burn(account, amount);
    }
}
