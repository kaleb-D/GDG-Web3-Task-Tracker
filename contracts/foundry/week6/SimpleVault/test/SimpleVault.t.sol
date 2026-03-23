// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/SimpleVault.sol";

contract SimpleVaultTest is Test {
    SimpleVault vault;
    address user = address(0xABC);

    function setUp() public {
        vault = new SimpleVault();
        vm.deal(user, 5 ether);
    }

    function testDeposit() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(user), 1 ether);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        vault.deposit{value: 2 ether}();
        uint256 balanceBefore = user.balance;
        vault.withdraw();
        vm.stopPrank();

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, balanceBefore + 2 ether);
    }

    function testWithdrawEmptyReverts() public {
        vm.prank(user);
        vm.expectRevert("No balance to withdraw");
        vault.withdraw();
    }
}