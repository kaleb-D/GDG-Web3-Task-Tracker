// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MessageBoard {
    address public owner;
    string public message;

    event MessageChanged(string newMessage);

    constructor(string memory _initialMessage) {
        owner = msg.sender;
        message = _initialMessage;
    }

    function updateMessage(string memory _newMessage) public {
        require(msg.sender == owner, "Not the owner");
        message = _newMessage;
        emit MessageChanged(_newMessage);
    }
}