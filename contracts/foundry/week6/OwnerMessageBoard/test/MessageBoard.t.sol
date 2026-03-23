// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MessageBoard.sol";

contract MessageBoardTest is Test {
    MessageBoard board;
    address owner = address(0x123);
    address nonOwner = address(0x999);

    function setUp() public {
        vm.prank(owner);
        board = new MessageBoard("Hello World");
    }

    function testOwnerCanUpdate() public {
        vm.prank(owner);
        board.updateMessage("New Message");
        assertEq(board.message(), "New Message");
    }

    function testNonOwnerCannotUpdate() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        board.updateMessage("Hack!");
    }

    function testEventEmitted() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit MessageBoard.MessageChanged("Testing Event");
        board.updateMessage("Testing Event");
    }
}