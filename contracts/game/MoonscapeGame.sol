pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";

import "./../nfts/CityNft.sol";
import "./../nfts/CityFactory.sol";

contract MoonscapeGame is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    address MSCP;
    address cityNft;
    address cityFactory;

    address public verifier;

    struct Balance {
		uint256 totalSpent;      	// total amount of spend mscp
		uint256 stakeAmount;        // current amount of staked mscp
    }

    /// @dev userAddress => Balance struct
    mapping(address => Balance) public balances;

    mapping(uint => address) public cityOwners;

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

    event ImportCity(address indexed owner, uint indexed id);
    event ExportCity(address indexed owner, uint indexed id);
    event MintCity(address indexed owner, uint indexed id);

    constructor(
        address _mscpToken,
        address _cityNft,
        address _cityFactory,
        address _verifier
    ) public {
        MSCP = _mscpToken;
        cityNft = _cityNft;
        cityFactory = _cityFactory;
        verifier = _verifier;
    }

    //////////////////////////////////////////////////////////////////
    // 
    // Moonscape (MSCP) to Moondust
    // 
    //////////////////////////////////////////////////////////////////

    function purchaseMoondust(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(msg.sender) >= _amount, "not enough tokens to deposit");
        require(_token.transferFrom(msg.sender, address(this), _amount), "transfer of tokens to contract failed");

        Balance storage _balance  = balances[msg.sender];
        _balance.totalSpent = _amount.add(_balance.totalSpent);

        emit Spent(msg.sender, _amount, block.timestamp, _balance.totalSpent);
    }

    function stakeForMoondust(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(msg.sender) >= _amount, "not enough tokens to deposit");
        require(_token.transferFrom(msg.sender, address(this), _amount), "transfer of tokens to contract failed");

        Balance storage _balance  = balances[msg.sender];
        _balance.stakeAmount = _amount.add(_balance.stakeAmount);

        emit Stake(msg.sender, _amount, block.timestamp, _balance.stakeAmount);
    }

    function unstakeForMoondust(uint256 _amount) external {
        require(_amount > 0, "invalid spend amount");

        Balance storage _balance  = balances[msg.sender];
        require(_amount <= _balance.stakeAmount, "can't unstake more than staked");

        IERC20 _token = IERC20(MSCP);
        require(_token.balanceOf(address(this)) >= _amount, "insufficient contract balance");

        require(_token.transfer(msg.sender, _amount), "Failed to transfer token from contract to user");

        _balance.stakeAmount = _balance.stakeAmount.sub(_amount);

        emit Unstake(msg.sender, _amount, block.timestamp, _balance.stakeAmount);
    }


    ////////////////////////////////////////
    //
    // City NFTs
    //
    ////////////////////////////////////////

    function importCity(uint _id) external {
        require(_id > 0, "0");

        CityNft nft = CityNft(CityNft);
        require(nft.ownerOf(_id) == msg.sender, "Not city owner");

        nft.safeTransferFrom(msg.sender, address(this), _id);
        cityOwners[_id] = msg.sender;

        emit ImportCity(msg.sender, _id, block.timestamp);
    }

    function exportCity(uint _id) external {
        require(cityOwners[_id] == msg.sender, "Not the owner");

        CityNft nft = CityNft(CityNft);
        nft.safeTransferFrom(address(this), msg.sender, _id);

        delete cityOwners[_id];

        emit ExportCity(msg.sender, _id, block.timestamp);        
    }

    function mintCity(uint _id, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), _id));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == verifier, "Lighthouse: SIG");
        }

        CityFactory factory = CityFactory(cityFactory);
        factory.mint(_id);

        emit MintCity(msg.sender, _id, block.timestamp);
    }
}