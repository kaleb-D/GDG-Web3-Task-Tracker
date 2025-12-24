// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract ATM {
    address public owner;
    bool public paused;

    struct Account {
        bytes32 pinHash;     // Store hash only; on-chain data is public
        uint256 balance;     // Use uint for money to avoid negative values
    }

    mapping(address => Account) private accounts;
    mapping(address => bool) private hasAccount; // Explicit existence check

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    ///  Creates an account tied to caller's address
    function createAccount(string calldata pin) external whenNotPaused {
        require(!hasAccount[msg.sender], "Account exists");

        accounts[msg.sender] = Account({
            pinHash: keccak256(bytes(pin)), // Hash prevents plaintext PIN storage
            balance: 0
        });

        hasAccount[msg.sender] = true;
    }

    ///  Deposit ETH after PIN verification
    function deposit(string calldata pin) external payable whenNotPaused {
        require(hasAccount[msg.sender], "No account");
        require(msg.value > 0, "Zero deposit");
        require(
            accounts[msg.sender].pinHash == keccak256(bytes(pin)),
            "Wrong pin"
        );

        accounts[msg.sender].balance += msg.value;
    }

    /// Withdraw ETH using checks-effects-interactions pattern
    function withdraw(uint256 amount, string calldata pin) external whenNotPaused {
        require(hasAccount[msg.sender], "No account");

        Account storage acc = accounts[msg.sender];
        require(acc.pinHash == keccak256(bytes(pin)), "Wrong pin");
        require(acc.balance >= amount, "Insufficient balance");

        acc.balance -= amount; // State change before external call

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }

    ///  Returns caller balance after PIN verification
    function balanceOf(string calldata pin) external view returns (uint256) {
        require(hasAccount[msg.sender], "No account");
        require(
            accounts[msg.sender].pinHash == keccak256(bytes(pin)),
            "Wrong pin"
        );

        return accounts[msg.sender].balance;
    }

    /// Emergency stop pattern
    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}