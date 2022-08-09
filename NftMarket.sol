// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/utils/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract Marketplace {
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;
    Counters.Counter private _nftSold;

    address payable owner;

    // uint256 public mintingCost =1 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

  

    struct _NftItem {
        ListingStatus status;
        uint256 orderId;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        address nftAddress;
        uint256 quantity;
        bool IsERC721;
        bool IsFixedSell;
    }

    mapping(uint256 => _NftItem) public NftItems;

    event create1155(
        address,
        uint256 orderId,
        uint256 tokenId,
        uint256 price,
        address nftAddress,
        bool isErc721,
        uint256 quantity,
        bool
    );
    event create721(
        address,
        uint256 tokenId,
        uint256 price,
        address nftAddress,
        bool isErc721,
        bool
    );
    event buynftevent(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price
    );
    event ItemListed(
        address,
        address nftAddress,
        uint256 orderId,
        uint256 newPrice
    );

    function sellNft(
        uint256 orderId,
        uint256 tokenId,
        uint256 price,
        address nftAddress,
        uint256 quantity,
        bool isErc721
    ) public payable {
        _orderIds.increment();
        uint256 itemId = _orderIds.current();
        if (isErc721 == false) {
            NftItems[itemId] = _NftItem(
                ListingStatus.Active,
                orderId,
                tokenId,
                payable(address(this)),
                payable(address(0)),
                price,
                nftAddress,
                quantity,
                false,
                true
            );
            emit create1155(
                msg.sender,
                orderId,
                tokenId,
                price,
                nftAddress,
                false,
                quantity,
                true
            );
        } else {
            NftItems[itemId] = _NftItem(
                ListingStatus.Active,
                orderId,
                tokenId,
                payable(address(this)),
                payable(address(0)),
                price,
                nftAddress,
                0,
                true,
                true
            );
            emit create721(msg.sender, tokenId, price, nftAddress, true, true);
        }
    }

    function buyNft(
        uint256 oderid,
        uint256 tokenid,
        address nftAddress,
        uint256 quantity,
        address payable seller,
        address payable buyer,
        uint256 price
    ) public payable {
        _NftItem storage listedItem = NftItems[oderid];

        listedItem.buyer = payable(msg.sender);
        listedItem.status = ListingStatus.Sold;

        address payable ownerAddress = listedItem.seller;
        if (listedItem.buyer == address(0)) {
            ownerAddress = listedItem.buyer;
        }
        _nftSold.increment();

        ERC1155(nftAddress).safeTransferFrom(
            buyer,
            seller,
            tokenid,
            quantity,
            ""
        );
        ERC721(nftAddress).transferFrom(msg.sender, seller, tokenid);

        payable(NftItems[oderid].seller).transfer(price);
        emit buynftevent(seller, buyer, tokenid, NftItems[oderid].price);
    }

    function cancelsell(uint256 orderId) public {
        _NftItem storage listedItem = NftItems[orderId];
        listedItem.status = ListingStatus.Cancelled;
        ERC1155(listedItem.nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            listedItem.tokenId,
            listedItem.quantity,
            ""
        );
        ERC721(listedItem.nftAddress).transferFrom(
            address(this),
            msg.sender,
            listedItem.tokenId
        );
    }


function MarketItems() public view returns (_NftItem[] memory) {
        uint256 itemCount = _orderIds.current();
        uint256 unSoldItem = _orderIds.current() - _nftSold.current();
        uint256 currentIndex = 0;

        _NftItem[] memory items = new _NftItem[](unSoldItem);
        for (uint256 i = 0; i < itemCount; i++) {
            if (NftItems[i + 1].seller == address(this)) {
                uint256 currentId = i + 1;
                _NftItem storage currentItem = NftItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItembyBuyer() public view returns (_NftItem[] memory) {
        uint256 totalItemCount = _orderIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NftItems[i + 1].buyer == msg.sender) {
                itemCount += 1;
            }
        }
        _NftItem[] memory items = new _NftItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NftItems[i + 1].buyer == msg.sender) {
                uint256 currentid = i + 1;
                _NftItem storage currentItem = NftItems[currentid];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItembySeller() public view returns (_NftItem[] memory) {
        uint256 totalItemCount = _orderIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NftItems[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        _NftItem[] memory items = new _NftItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NftItems[i + 1].seller == msg.sender) {
                uint256 currentid = i + 1;
                _NftItem storage currentItem = NftItems[currentid];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function viewListingById(uint256 _id)
        public
        view
        returns (_NftItem memory)
    {
        return NftItems[_id];
    }

    function updateListing(
        address nftAddress,
        uint256 orderId,
        uint256 newPrice
    ) external {
        NftItems[orderId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, orderId, newPrice);
    }
}
