// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {
    
    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        bool ended;
    }

    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256) public pendingReturns;

    //  createAuction
    function createAuction(uint256 _duration) public {
        auctionCount++;
        auctions[auctionCount] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + _duration,
            ended: false
        });
    }

    //  bid
    function bid(uint256 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction already ended.");
        require(msg.value > auction.highestBid, "Bid not high enough.");

        // If there was a previous bidder, add their bid to pendingReturns
        if (auction.highestBid != 0) {
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    // withdraw
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // endAuction
    function endAuction(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended.");
        require(!auction.ended, "endAuction has already been called.");

        auction.ended = true;
        payable(auction.seller).transfer(auction.highestBid);
    }
}