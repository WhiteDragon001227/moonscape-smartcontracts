// Seascape NFT
// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

import "./../openzeppelin/contracts/access/Ownable.sol";
import "./../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./../openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";

/// @author Medet Ahmetson
contract RoverNft is ERC721, ERC721Burnable, Ownable {
    mapping(uint => uint8) public typeOf;
    mapping(uint => bool) public minted;
    mapping(address => bool) public minters;

    event SetMinter(address indexed minter);
    event UnsetMinter(address indexed minter);
    event Minted(address indexed owner, uint indexed id, uint8 category, uint time);

    constructor() public ERC721("MoonCity", "CITY") {
        minters[msg.sender] = true;

        emit SetMinter(msg.sender);
    }

    function mint(uint _tokenId, uint8 _type, address _to) external returns(bool) {
        if (!minters[msg.sender] || minted[_tokenId] || _to == address(0) || _type > 8) {
            return false;
        }

      	typeOf[_tokenId] = _type;

        _safeMint(_to, _tokenId);

      	emit Minted(_to, _tokenId, _type, block.timestamp);
      	return true;
    }

    function setMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "invalid factory address");
        require(!minters[_minter], "already a minter");
        minters[_minter] = true;

        emit SetMinter(_minter);
    }

    function unsetMinter(address _minter) public onlyOwner {
        require(!minters[_minter], "already a minter");

        delete minters[_minter];

        emit UnsetMinter(_minter);
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }
}
