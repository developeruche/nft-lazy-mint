// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


/// @dev Importing most of the NFt logic from Openzepplin contracts, EIP712 was employed in how signatures was handled in this project 
contract NFTmint is ERC721, ERC721URIStorage, Ownable, EIP712 {
    string private constant SIGNING_DOMAIN = "DUC-NFT-MINT-DOMAIN-nft.mint.com";
    string private constant SIGNATURE_VERSION = "1";
    address public claimer;

    constructor(address _claimer) ERC721("NFT mint", "NFTM") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        claimer = _claimer;
    }

    // This struct holds the details of the NFT
    struct NFTmintVoucher {
        uint256 tokenId;
        uint256 price;
        string uri;
        address buyer;
        bytes signature;
    }

    /// @dev this function follows the eip 712 standard:--> read this for more details ==>  https://eips.ethereum.org/EIPS/eip-712
    /// @param voucher: this is the struct of the nft data of the nft to be minted
    function recover(NFTmintVoucher calldata voucher) public view returns (address signer) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTmintVoucher(uint256 tokenId,uint256 price,string uri,address buyer)"),
            voucher.tokenId,
            voucher.price,
            keccak256(bytes(voucher.uri)),
            voucher.buyer
        )));
        signer = ECDSA.recover(digest, voucher.signature);
    }

    /// @dev this is the mint function, this would only mint if the signature and the value passed into the function matches the respected values
    /// @param voucher: this is the struct holding the data consigning the nft tot be minted
    function safeMint(NFTmintVoucher calldata voucher)
        public
        payable
    {
        require(claimer == recover(voucher), "Wrong signature.");
        require(msg.value >= voucher.price, "Not enough ether sent.");
        _safeMint(voucher.buyer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}