// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedWallet {
    // STEP 1: Deposit Struct
    struct Deposit {
        address user;
        uint256 amount;
        uint256 time;
    }

    // STEP 2: State Variables
    address public owner;
    uint256 public totalBalance;
    mapping(address => uint256) public balances;
    Deposit[] public deposits;

    // STEP 3: Constructor
    constructor() {
        owner = msg.sender;
    }

    // STEP 4: deposit
    function deposit() public payable {
        require(msg.value > 0, "Must deposit something");
        
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        
        deposits.push(Deposit({
            user: msg.sender,
            amount: msg.value,
            time: block.timestamp
        }));
    }

    // STEP 5: withdraw (Only Owner)
    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(address(this).balance >= _amount, "Insufficient vault balance");
        
        totalBalance -= _amount;
        payable(owner).transfer(_amount);
    }
}