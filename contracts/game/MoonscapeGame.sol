pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/math/SafeMath.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./../nfts/CityNft.sol";

contract MoonscapeGame is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant scaler = 10**18;

    address MSCP;
    address cityNft;
    address roverNft;
    address scapeNft;

    address private constant dead = 0x000000000000000000000000000000000000dEaD;

    address public verifier;

    address public feeTo;

    struct Balance {
		uint256 totalSpent;      	// total amount of spend mscp
		uint256 stakeAmount;        // current amount of staked mscp
    }

    /// @dev userAddress => Balance struct
    mapping(address => Balance) public balances;

    mapping(uint => address) public cityOwners;
    mapping(uint => address) public roverOwners;
    /// @dev session id => user => building => scape id
    mapping(uint => mapping(address => mapping(uint => uint))) public buildingScapeBurns;
    /// @dev session id => user => uint
    mapping(uint => mapping(address => uint)) public connectionScapeBurns;

    event Spent(address indexed spender, uint256 amount, uint256 spentTime, uint256 totalSpent);
    event Stake(address indexed staker, uint256 amount, uint256 stakeTime, uint256 stakeAmount);
    event Unstake(address indexed staker, uint256 amount, uint256 unstakeTime, uint256 stakeAmount);

    event ImportCity(address indexed owner, uint indexed id, uint time);
    event ExportCity(address indexed owner, uint indexed id, uint time);
    event MintCity(address indexed owner, uint amount, uint indexed id, uint8 _category);
    event BurnScapeForBuilding(address indexed owner, uint indexed scapeId, uint sessionId, uint cityId, uint indexed buildingId);
    event BurnScapeForConnection(address indexed owner, uint indexed scapeId, uint sessionId);

    event ImportRover(address indexed owner, uint indexed id, uint time);
    event ExportRover(address indexed owner, uint indexed id, uint time);
    event MintRover(address indexed owner, uint amount, uint indexed id, uint8 _type);

    constructor(
        address _mscpToken,
        address _cityNft,
        address _roverNft,
        address _scapeNft,
        address _verifier,
        address _feeTo
    ) public {
        MSCP = _mscpToken;
        cityNft = _cityNft;
        roverNft = _roverNft;
        scapeNft = _scapeNft;
        verifier = _verifier;
        feeTo = _feeTo;
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
        require(_token.transferFrom(msg.sender, feeTo, _amount), "transfer of tokens to contract failed");

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

    function mintCity(uint _id, uint8 _category, uint _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), cityNft, _id, _amount, _category));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, _r, _s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(cityNft);
        require(nft.mint(_id, _category, msg.sender), "Failed to mint city");

        emit MintCity(msg.sender, _amount, _id, _category);
    }

    /////////////////////////////////////////////////////////////////
    //
    // Burn Scape NFT for bonus in City
    //
    /////////////////////////////////////////////////////////////////

    function burnScapeForBuilding(uint _sessionId, uint _stakeId, uint _cityId, uint _buildingId, uint _scapeNftId, uint _power, uint8 _v, bytes32[2] calldata sig) external {
        require(buildingScapeBurns[_sessionId][msg.sender][_buildingId] == 0, "Already burnt");
        require(_sessionId > 0, "invalid sessionId");
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(_sessionId, _stakeId, _cityId, _buildingId, _scapeNftId, _power));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, sig[0], sig[1]);

	    require(recover == verifier, "Verification failed about burnScapeForBuilding");
        }

        CityNft nft = CityNft(scapeNft);
        require(nft.ownerOf(_scapeNftId) == msg.sender, "Not the owner");

        nft.safeTransferFrom(msg.sender, dead, _scapeNftId);

        buildingScapeBurns[_sessionId][msg.sender][_buildingId] = _scapeNftId;

        emit BurnScapeForBuilding(msg.sender, _scapeNftId, _sessionId, _cityId, _buildingId);
    }

    function burnScapeForConnection(uint _sessionId, uint _scapeNftId, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(connectionScapeBurns[_sessionId][msg.sender] == 0, "Already burnt");
        require(_sessionId > 0, "invalid sessionId");

        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, _scapeNftId, _sessionId));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, _r, _s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(scapeNft);
        nft.safeTransferFrom(msg.sender, dead, _scapeNftId);

        connectionScapeBurns[_sessionId][msg.sender] = _scapeNftId;

        emit BurnScapeForConnection(msg.sender, _scapeNftId, _sessionId);
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

    function mintRover(uint _id, uint8 _type, uint  _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), roverNft, _id, _amount, _type));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, _r, _s);

	    require(recover == verifier, "sig");
        }

        CityNft nft = CityNft(roverNft);
        require(nft.mint(_id, _type, msg.sender), "Failed to mint rover");

        emit MintRover(msg.sender, _amount, _id, _type);
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