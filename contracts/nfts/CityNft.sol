// Seascape NFT
// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/utils/Counters.sol";
import "./../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./../openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";

/// @author Medet Ahmetson
contract CityNft is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenId;

    struct Params {
    	uint8 category;
    	uint8 building1;
        uint8 building2;
        uint8 building3;
        uint8 building4;
        uint8 building5;
    }

    address private factory;

    mapping(uint256 => Params) public paramsOf;

    event Minted(
        address indexed owner,
        uint256 indexed id,
        uint8 category,
        uint8 building1,
        uint8 building2,
        uint8 building3,
        uint8 building4,
        uint8 building5
    );

    constructor() public ERC721("MoonCity", "CITY") {
      	tokenId.increment();
    }

    modifier onlyFactory() {
      	require(factory == _msgSender(), "only factory can call the method");
	      _;
    }

    function mint(
        address _to,
        uint8 category,
        uint8 building1,
        uint8 building2,
        uint8 building3,
        uint8 building4,
        uint8 building5
    )
        public
        onlyFactory
        returns(uint256)
    {
        require(_to != address(0), "invalid receiver address");

        uint256 _tokenId = tokenId.current();
      	paramsOf[_tokenId] = Params(
            category,
            building1,
            building2,
            building3,
            building4,
            building5
        );
      	tokenId.increment();

        _safeMint(_to, _tokenId);

      	emit Minted(
            _to,
            _tokenId,
            category,
            building1,
            building2,
            building3,
            building4,
            building5
        );
      	return _tokenId;
    }

    function setOwner(address _owner) public onlyOwner {
	     transferOwnership(_owner);
    }

    function setFactory(address _factory) public onlyOwner {
        require(_factory != address(0), "invalid factory address");
        factory = _factory;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }
}
