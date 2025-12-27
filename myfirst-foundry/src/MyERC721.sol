//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721 is ERC721URIStorage {
    uint256 private _tokenIds;

    constructor() ERC721(unicode"Secret Place NFT", "Secret Place") {}

    function mint(address _to, string memory _tokenURI) external returns (uint256) {
        uint256 newTokenId = _tokenIds;
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _tokenIds++;
        return newTokenId;
    }
}
