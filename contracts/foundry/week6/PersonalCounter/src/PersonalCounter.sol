// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PersonalCounter {
    mapping(address => uint256) public counts;

    function increment() public {
        counts[msg.sender] += 1;
    }

    function reset() public {
        require(counts[msg.sender] > 0, "Already zero");
        counts[msg.sender]= 0;
    }
}
