// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PersonalCounter.sol";

contract PersonalCounterTest is Test {
    PersonalCounter counter;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        counter = new PersonalCounter();
    }

    function testIncrement() public {
        vm.prank(user1);
        counter.increment();
        assertEq(counter.counts(user1), 1);
    }

    function testReset() public {
        vm.prank(user1);
        counter.increment();
        vm.prank(user1);
        counter.reset();
        assertEq(counter.counts(user1), 0);
    }

    function testCannotResetOtherUser() public {
        vm.prank(user1);
        counter.increment();

        // User2 tries to reset User1's counter? 
        // In this logic, reset() only resets the msg.sender's own counter.
        // So User2 calling reset will only affect User2's (already zero) counter.
        vm.prank(user2);
        vm.expectRevert("Counter already zero");
        counter.reset();
        
        assertEq(counter.counts(user1), 1); // User1 remains untouched
    }
}