// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleVault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        balances[msg.sender] = 0; // Reset before transfer (Security!)
        payable(msg.sender).transfer(amount);
    }
}