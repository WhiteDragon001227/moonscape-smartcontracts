pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";

import "./../nfts/CityNft.sol";

contract MoonscapeGame is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    address MSCP;
    address cityNft;
    address roverNft;
    address scapeNft;

    address public verifier;

    struct Balance {
		uint256 totalSpent;      	// total amount of spend mscp
		uint256 stakeAmount;        // current amount of staked mscp
    }

    /// @dev userAddress => Balance struct
    mapping(address => Balance) public balances;

    mapping(uint => address) public cityOwners;
    mapping(uint => address) public roverOwners;

    event Spent(address indexed spender, uint256 amount, uint256 spentTime, uint256 totalSpent);
    event Stake(address indexed staker, uint256 amount, uint256 stakeTime, uint256 stakeAmount);
    event Unstake(address indexed staker, uint256 amount, uint256 unstakeTime, uint256 stakeAmount);

    event ImportCity(address indexed owner, uint indexed id);
    event ExportCity(address indexed owner, uint indexed id);
    event BurnScape(uint indexed scapeId, uint indexed cityId, uint indexed buildingId);

    event ImportRover(address indexed owner, uint indexed id);
    event ExportRover(address indexed owner, uint indexed id);

    constructor(
        address _mscpToken,
        address _cityNft,
        address _roverNft,
        address _scapeNft,
        address _verifier
    ) public {
        MSCP = _mscpToken;
        cityNft = _cityNft;
        roverNft = _roverNft;
        scapeNft = _scapeNft;
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

        CityNft nft = CityNft(cityNft);
        require(nft.ownerOf(_id) == msg.sender, "Not city owner");

        nft.safeTransferFrom(msg.sender, address(this), _id);
        cityOwners[_id] = msg.sender;

        emit ImportCity(msg.sender, _id, block.timestamp);
    }

    function exportCity(uint _id) external {
        require(cityOwners[_id] == msg.sender, "Not the owner");

        CityNft nft = CityNft(cityNft);
        nft.safeTransferFrom(address(this), msg.sender, _id);

        delete cityOwners[_id];

        emit ExportCity(msg.sender, _id, block.timestamp);        
    }

    function mintCity(uint _id, uint8 _category, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), cityNft, _id, _category));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(cityNft);
        require(nft.mint(_id, _category, msg.sender), "Failed to mint city");
    }

    /////////////////////////////////////////////////////////////////
    //
    // Burn Scape NFT for bonus in City
    //
    /////////////////////////////////////////////////////////////////

    function burnScape(uint _scapeId, uint _cityId, uint _buildingId, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(_scapeId, _cityId, _buildingId));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(scapeNft);
        nft.burn(_scapeId);

        CityNft city = CityNft(scapeNft);
        require(nft.ownerOf(_scapeId) == cityOwners[_cityId] ||
        nft.owerOf(_scapeId) == city.ownerOf(_cityId), "Not the owner");

        emit BurnScape(_scapeId, _cityId, _buildingId, block.timestamp);
    }

    /////////////////////////////////////////////////////////////
    //
    // Rover
    //
    //////////////////////////////////////////////////////////////

    function importRover(uint _id) external {
        require(_id > 0, "0");

        CityNft nft = CityNft(roverNft);
        require(nft.ownerOf(_id) == msg.sender, "Not rover owner");

        nft.safeTransferFrom(msg.sender, address(this), _id);
        roverOwners[_id] = msg.sender;

        emit ImportRover(msg.sender, _id, block.timestamp);
    }

    function exportRover(uint _id) external {
        require(roverOwners[_id] == msg.sender, "Not the owner");

        CityNft nft = CityNft(roverNft);
        nft.safeTransferFrom(address(this), msg.sender, _id);

        delete roverOwners[_id];

        emit ExportRover(msg.sender, _id, block.timestamp);        
    }

    function mintRover(uint _id, uint8 _type, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), roverNft, _id, _type));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(roverNft);
        require(nft.mint(_id, _type, msg.sender), "Failed to mint rover");
    }
}