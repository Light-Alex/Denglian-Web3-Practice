// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721Permit } from "@soliditylabs/erc721-permit/contracts/ERC721Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFTPermit is ERC721Permit, Ownable {
  uint256 private _lastTokenId;

  // Token URI映射
  mapping(uint256 => string) private _tokenURIs;
  
  constructor() ERC721Permit("ERC721 Permit NFT", "EPT") Ownable() {}

  function mint(address to, string memory uri) public onlyOwner returns (uint256) {
    uint256 tokenId = _lastTokenId++;
    _mint(to, tokenId);
    _tokenURIs[tokenId] = uri;
    return tokenId;
  }

  /**
  * @notice 获取Token URI
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(ownerOf(tokenId) != address(0), "Token does not exist");
      return _tokenURIs[tokenId];
  }

  function safeTransferFromWithPermit(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data,
    uint256 deadline,
    bytes memory signature
  ) external {
    _permit(msg.sender, tokenId, deadline, signature);
    safeTransferFrom(from, to, tokenId, _data);
  }
}
