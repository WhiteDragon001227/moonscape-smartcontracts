pragma solidity 0.6.7;

import "./../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./../openzeppelin/contracts/access/Ownable.sol";
import "./LighthouseTierInterface.sol";


/// @title RiverboatNft is a nft service platform
/// User can buy nft at a slots 1-5
/// In intervals of time slots are replenished and nft prices increase
/// @author Nejc Schneider
contract CityNftSale is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;

    bool public tradeEnabled = true;   // enable/disable buy function

    address public priceReceiver;      // this address receives the money from bought tokens
    address public currencyAddress;     // what users pay when buying
    address public nftAddress;          // address of nft which users will receive
    address public lighthouseTierAddress; // used for tier validation

    // session data
    uint32 public startTime,       // timestamp for session start
    uint32 public endTime,         // timestamp for session end
    uint32 public slotsAmount     // amount of different qualities


    struct Slot{
        uint256 startPrice,
        uint256 priceIncrease,
        uint256 nftsAmount
    }

    /// @dev quality => Quality struct
    // NOTE qualities mapping should start at index 0!
    mapping(uint256 => Slot) public slots;
    /// @dev slotId => interval => bool
    mapping(uint256 => mapping(uint256 => bool) public soldNfts;

    event Buy(
    );

    event StartSession(
    );

    event SetAddresses(
    );

    //--------------------------------------------------------------------
    //  external onlyOwner functions
    //--------------------------------------------------------------------

    /// @notice enable/disable buy function
    /// @param _tradeEnabled set tradeEnabled to true/false
    function enableTrade(bool _tradeEnabled) external onlyOwner {
        tradeEnabled = _tradeEnabled;
    }

    /// @notice change price receiver address
    /// @param _priceReceiver address of new receiver
    function setAddresses(
        address _priceReceiver,
        address _currencyAddress,
        address _nftAddress,
        address _lighthouseTierAddress
    )
        external
        onlyOwner
    {
        // NOTE if _lighthouseTierAddress is 0x0, means tier is not a requirement
        require(_priceReceiver != address(0), "invalid price receiver address");
        require(_currencyAddress != address(0), "invalid currency address");
        require(_nftAddress != address(0), "invalid nft address");

        priceReceiver = _priceReceiver;
        currencyAddress = _currencyAddress;
        nftAddress = _nftAddress;
        lighthouseTierAddress = _lighthouseTierAddress;

        emit SetAddresses(_priceReceiver, _currencyAddress, _nftAddress, _lighthouseTierAddress);
    }

    function setQuality(
        uint256 _quality,
        uint256 _startPrice,
        uint256 _priceIncrease,
        uint256 _nftsAmount
    )
        external
        onlyOwner
    {
        require(_startPrice > 0, "invalid start price");
        require(_priceIncrease > 0, "invalid price increase");
        require(_nftsAmount > 0, "invalid nfts amount");

        qualities[_quality].startPrice = _startPrice;
        qualities[_quality].priceIncrease = _priceIncrease;
        qualities[_quality].nftsAmount = _nftsAmount;

        emit SetQuality(_quality, _startPrice, _priceIncrease, _nftsAmount)
    }


    /// @dev start a new session, during which players are allowed to buy nfts
    /// @param _startTime timestamp at which session becomes active
    /// @param _slotsAmount amount of nft slots in a session
    function setSession(
        uint32 _startTime,
        uint32 _endTime,
        uint32 _slotsAmount
    )
        external
        onlyOwner
    {
        require(endTime <= now, "last session is still active");
        require(_startTime > now, "session should start in future");
        require(_endTime > _startTime, "end time should proceed start time");
        require(_slotsAmount > 0, "should use at least one slot");

        for(uint i = 0; i < _slotsAmount; i++) {
            require(qualities[i].nftsAmount > 0,
              "Each slot should be configured with setQuality function");
        }

        startTime = _startTime;
        endTime = _endTime;
        slotsAmount = _slotsAmount;

        emit StartSession(_startTime, _endTime, _slotsAmount);
    }

    /// @dev after session is finished owner can approve withdrawal of remaining nfts
    /// @param _sessionId session unique identifier
    /// @param _receiverAddress address which will receive the nfts
    function approveUnsoldNfts(address _receiverAddress)
        external
        onlyOwner
    {
        require(endTime <= now, "last session is still active");
        require(_receiverAddress != address(0), "invalid receiver address");
        IERC721(nftAddress).setApprovalForAll(_receiverAddress, true);
    }

    //--------------------------------------------------------------------
    // External functions
    //--------------------------------------------------------------------

    /// @notice buy nft at selected slot
    /// @param _sessionId session unique identifier
    /// @param _nftId id of nft
    function buy(uint256 _slotId) external {
        Session storage _session = sessions[_sessionId];
        //require stamements
        uint256 _currentInterval = getCurrentInterval(_sessionId);
        uint256 _currentPrice = getCurrentPrice(_slotId, _currentInterval);
        require(!soldNfts[_slotId][_currentInterval],
            "nft in this interval was sold");
        require(tradeEnabled, "trade is disabled");

        /// @dev make sure msg.sender has obtained tier in LighthouseTier.sol
        /// LighthouseTier.sol is external but trusted contract maintained by Seascape
        if(lighthouseTierAddress != address(0)){
            LighthouseTierInterface tier = LighthouseTierInterface(lighthouseTierAddress);
            require(tier.getTierLevel(msg.sender) > -1, "tier rank 0-4 is required");
        }

        // update state
        soldNfts[_slotId][_currentInterval] = true;

        /// make transactions
        IERC20(currencyAddress).safeTransferFrom(msg.sender, priceReceiver, _currentPrice);
        /// TODO need to figure out which nftId we're sending from contract
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, _nftId);

        /// emit events
        emit Buy(
          _sessionId,
          _currentInterval,
          _currentPrice,
          _nftId,
          msg.sender
        );
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

    /// @notice get remaining time in current interval
    /// @param _sessionId session unique identifier
    /// @return time in seconds
    function getIntervalTime(uint256 _slotId) external view returns(uint) {
        if(!isActive(_sessionId)) {
            return 0;
        } else {
            return (now - sessions[_sessionId]
              .startTime) % sessions[_sessionId].intervalDuration;
        }
    }

    //--------------------------------------------------------------------
    // public functions
    //--------------------------------------------------------------------

    /// @dev calculate current interval number
    /// @param _sessionId session unique identifier
    /// @return current interval number
    function getCurrentInterval(uint _slotId) public view returns(uint) {
        require(endTime <= now, "last session is still active");
        uint256 _intervalDuration = (endTime - startTime) / slots[_slotId].nftsAmount;
        uint256 _currentInterval = (now - startTime) / _intervalDuration;

        // @dev _currentInterval will start with 0 so last interval should be intervalsAmoun-1
        require(_currentInterval < slots[_slotId].nftsAmount,
            "_currentInterval > nftsAmount, session is finished");
        return _currentInterval;
    }

    /// @dev calculate current nft price
    /// @param _sessionId session unique identifier
    /// @param _currentInterval number of the current interval
    /// @return nft price for the current interval
    function getCurrentPrice(uint256 _slotId, uint256 _currentInterval)
        public
        view
        returns (uint)
    {
        // if _currentInterval = 0, session.startPrice will be returned
        uint256 _currentPrice = slots[_slotId].startPrice + slots[_slotId]
            .priceIncrease * _currentInterval;
        return _currentPrice;
    }

    /// @dev check if session is currently active
    /// @param _sessionId id to verify
    /// @return true/false depending on timestamp period of the sesson
    function isActive(uint256 _sessionId) internal view returns (bool){
        Session storage session = sessions[_sessionId];
        if(now >= session.startTime && now < session
            .startTime + session.intervalsAmount * session.intervalDuration){
            return true;
        }
        return false;
    }

    /// @dev check if session is already finished
    /// @param _sessionId id to verify
    /// @return true if session is finished
    function isFinished(uint256 _sessionId) internal view returns (bool){
        Session memory session = sessions[_sessionId];
        if(now > session.startTime + session.intervalsAmount * session.intervalDuration)
            return true;
        return false;
    }

    //--------------------------------------------------------------------
    // private functions
    //--------------------------------------------------------------------

    /// @dev retrieve executing chain id
    /// @return network identifier
    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

}
