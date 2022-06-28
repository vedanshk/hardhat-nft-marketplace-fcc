//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketPlace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress , uint256 tokenId);
error NftAddressprice__PriceNotMet(address nftAddress , uint256 tokenId);
contract NftMarketplace is ReentrancyGuard {
    /*

    1.`listItem`: List NFTs on the marketplace
    2.`buyItem` : Buy the NFTs
    3.`cancleItem`: Cancle a listing
    4.`updateListing`: Update Price
    5.`withdrawProceeds`: Withdraw payment for my nft 


    */
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress ,
        uint256 indexed tokenId,
        uint256 price

    );
    // State Variable
    struct Listing {
        uint256 price;
        address seller;
    }


    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // proceeced
    mapping(address => uint256 ) private s_proceeds;


    // State Variables ends

    // Modifiers
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }

        _;
    }

    modifier isOwner( address nftAddress , uint256 tokenId , address spender){

       IERC721 nft = IERC721(nftAddress );
       address owner =  nft.ownerOf(tokenId);
       if(spender != owner){
        revert NftMarketplace__NotOwner();
       }
       _;
    }

    modifier isListed(address nftAddress  , uint256 tokenId) {

        Listing memory listing =  s_listings[nftAddress][tokenId];

        if(listing.price <=0){

          revert   NftMarketplace__NotListed(nftAddress , tokenId);
        }
     
        _;
    }


    // Modifiers Ends
    /*
        * @notice Method for listing your NFT on the marketplace
        * @param nftAddress : Address of the NFT
        * @param tokenId : The Token ID of the Nft
        * @param price : sale price of the listed NFT
        * @dev Tecnically , we could  have the contract be the escrow for the NFTs
        * but this way people can still hld their NFT when listed.

    */



    ///Main Functions
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
       
    ) external

    notListed(nftAddress , tokenId , msg.sender)
    isOwner(nftAddress , tokenId , msg.sender)
    
     {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        // 1. Send the NFT to the contract . Transfer -> contract "hold" the NFT.
        // 2. Owners can still hold their NFT , and give the marketplace approval
        // to sell the NFT

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketPlace();
        }

        // array ? mapping?
        // mappingt

        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);

        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress , uint256 tokenId) external payable nonReentrant isListed(nftAddress , tokenId) {

            Listing memory  listedItem = s_listings[nftAddress][tokenId];
            
            if(msg.value < listedItem.price){

                revert NftAddressprice__PriceNotMet(nftAddress , tokenId);
            }


           s_proceeds[listedItem.seller] += msg.value;

           delete (s_listings[nftAddress][tokenId]);

           // We just don't add money to seller //
           // Have them withdraw to later
           IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
            // check to sure the 

          emit ItemBought(msg.sender , nftAddress , tokenId , listedItem.price);
        
    }

//Reentrancy 
// oracle attaks


}
