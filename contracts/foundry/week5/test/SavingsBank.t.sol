// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

/**
 * @title SavingsBankTest
 * @notice Full test suite for the SavingsBank contract
 */
contract SavingsBankTest is Test {
    // Redeclare events for vm.expectEmit
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed owner, uint256 amount);

    SavingsBank public bank;

    // ── Test Actors ──
    address public owner;
    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");
    address public carol = makeAddr("carol");

    // ── Common amounts ──
    uint256 constant ONE_ETH    = 1 ether;
    uint256 constant HALF_ETH   = 0.5 ether;
    uint256 constant MIN_DEP    = 0.001 ether;
    uint256 constant BELOW_MIN  = 0.0001 ether;

    // ─────────────────────────────────────────────────────────────
    //  Setup
    // ─────────────────────────────────────────────────────────────

    function setUp() public {
        owner = address(this);
        bank  = new SavingsBank();

        // Fund test users
        vm.deal(alice, 10 ether);
        vm.deal(bob,   10 ether);
        vm.deal(carol, 10 ether);
    }

    // ─────────────────────────────────────────────────────────────
    //  1. Deposit Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice A user can deposit ETH successfully
    function test_DepositSucceeds() public {
        vm.prank(alice);
        bank.deposit{value: ONE_ETH}();

        assertEq(bank.getBalanceOf(alice), ONE_ETH, "Balance should equal deposit");
    }

    /// @notice Depositing updates the balance correctly
    function test_DepositUpdatesBalance() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();
        bank.deposit{value: HALF_ETH}();
        vm.stopPrank();

        assertEq(bank.getBalanceOf(alice), ONE_ETH + HALF_ETH, "Balance should accumulate");
    }

    /// @notice Deposit emits the Deposited event
    function test_DepositEmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deposited(alice, ONE_ETH);
        bank.deposit{value: ONE_ETH}();
    }

    /// @notice Depositing zero ETH should revert
    function test_DepositZeroReverts() public {
        vm.prank(alice);
        vm.expectRevert(SavingsBank.ZeroAmount.selector);
        bank.deposit{value: 0}();
    }

    /// @notice Deposit below minimum should revert
    function test_DepositBelowMinimumReverts() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.BelowMinimumDeposit.selector,
                BELOW_MIN,
                MIN_DEP
            )
        );
        bank.deposit{value: BELOW_MIN}();
    }

    // ─────────────────────────────────────────────────────────────
    //  2. Withdrawal Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice A user can withdraw their own funds
    function test_WithdrawSucceeds() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();

        uint256 balanceBefore = alice.balance;
        bank.withdraw(ONE_ETH);
        uint256 balanceAfter = alice.balance;
        vm.stopPrank();

        assertEq(balanceAfter - balanceBefore, ONE_ETH, "Alice should receive her ETH back");
    }

    /// @notice Balance updates correctly after withdrawal
    function test_WithdrawUpdatesBalance() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();
        bank.withdraw(HALF_ETH);
        vm.stopPrank();

        assertEq(bank.getBalanceOf(alice), HALF_ETH, "Remaining balance should be half");
    }

    /// @notice Withdrawal emits the Withdrawn event
    function test_WithdrawEmitsEvent() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(alice, ONE_ETH);
        bank.withdraw(ONE_ETH);
        vm.stopPrank();
    }

    /// @notice A user cannot withdraw more than their balance
    function test_WithdrawMoreThanBalanceReverts() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();

        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.InsufficientBalance.selector,
                2 ether,
                ONE_ETH
            )
        );
        bank.withdraw(2 ether);
        vm.stopPrank();
    }

    /// @notice A user cannot withdraw with zero balance
    function test_WithdrawWithNoBalanceReverts() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.InsufficientBalance.selector,
                ONE_ETH,
                0
            )
        );
        bank.withdraw(ONE_ETH);
    }

    /// @notice Withdrawing zero should revert
    function test_WithdrawZeroReverts() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();
        vm.expectRevert(SavingsBank.ZeroAmount.selector);
        bank.withdraw(0);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────
    //  3. Total Contract Balance Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice Contract total balance reflects deposits
    function test_ContractBalanceReflectsDeposits() public {
        vm.prank(alice);
        bank.deposit{value: ONE_ETH}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        assertEq(bank.getTotalBalance(), 3 ether, "Total should be sum of all deposits");
    }

    /// @notice Total balance decreases after withdrawal
    function test_ContractBalanceDecreasesAfterWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: ONE_ETH}();

        vm.prank(bob);
        bank.deposit{value: ONE_ETH}();

        vm.prank(alice);
        bank.withdraw(ONE_ETH);

        assertEq(bank.getTotalBalance(), ONE_ETH, "Total should decrease by withdrawn amount");
    }

    // ─────────────────────────────────────────────────────────────
    //  4. getBalance / getBalanceOf Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice getBalance returns caller's own balance
    function test_GetBalanceReturnsSelfBalance() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();
        uint256 bal = bank.getBalance();
        vm.stopPrank();

        assertEq(bal, ONE_ETH);
    }

    /// @notice getBalanceOf returns correct balance for any address
    function test_GetBalanceOfReturnsCorrectBalance() public {
        vm.prank(alice);
        bank.deposit{value: ONE_ETH}();

        assertEq(bank.getBalanceOf(alice), ONE_ETH);
        assertEq(bank.getBalanceOf(bob), 0);
    }

    // ─────────────────────────────────────────────────────────────
    //  5. BONUS: Multiple Users
    // ─────────────────────────────────────────────────────────────

    /// @notice Multiple users can deposit and balances are tracked independently
    function test_MultipleUsersDepositIndependently() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(carol);
        bank.deposit{value: 3 ether}();

        assertEq(bank.getBalanceOf(alice), 1 ether, "Alice balance wrong");
        assertEq(bank.getBalanceOf(bob),   2 ether, "Bob balance wrong");
        assertEq(bank.getBalanceOf(carol),  3 ether, "Carol balance wrong");
        assertEq(bank.getTotalBalance(),    6 ether, "Total balance wrong");
    }

    /// @notice Multiple users can withdraw their own funds without affecting others
    function test_MultipleUsersWithdrawIndependently() public {
        // Deposits
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        vm.prank(bob);
        bank.deposit{value: 3 ether}();

        // Alice withdraws
        vm.prank(alice);
        bank.withdraw(1 ether);

        // Verify
        assertEq(bank.getBalanceOf(alice), 1 ether, "Alice remaining wrong");
        assertEq(bank.getBalanceOf(bob),   3 ether, "Bob should be untouched");
        assertEq(bank.getTotalBalance(),   4 ether, "Total should reflect Alice's withdrawal");
    }

    // ─────────────────────────────────────────────────────────────
    //  6. BONUS: Withdrawal Cooldown Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice User cannot withdraw twice within the cooldown window
    function test_WithdrawCooldownPreventsImmediateSecondWithdraw() public {
        vm.startPrank(alice);
        bank.deposit{value: 2 ether}();
        bank.withdraw(HALF_ETH);

        // Immediately try again — should revert
        vm.expectRevert();
        bank.withdraw(HALF_ETH);
        vm.stopPrank();
    }

    /// @notice User can withdraw again after cooldown expires
    function test_WithdrawSucceedsAfterCooldown() public {
        vm.startPrank(alice);
        bank.deposit{value: 2 ether}();
        bank.withdraw(HALF_ETH);

        // Fast-forward 60 seconds
        vm.warp(block.timestamp + 60);

        // Should succeed now
        bank.withdraw(HALF_ETH);
        vm.stopPrank();

        assertEq(bank.getBalanceOf(alice), 1 ether);
    }

    /// @notice First withdrawal is always allowed (no prior cooldown)
    function test_FirstWithdrawHasNoCooldown() public {
        vm.startPrank(alice);
        bank.deposit{value: ONE_ETH}();
        bank.withdraw(HALF_ETH); // Should never revert
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────
    //  7. BONUS: Owner Emergency Withdraw
    // ─────────────────────────────────────────────────────────────

    /// @notice Owner can emergency withdraw all funds
    function test_OwnerCanEmergencyWithdraw() public {
        // Deploy a fresh bank where carol is the owner (carol is a plain EOA that can receive ETH)
        vm.prank(carol);
        SavingsBank carolBank = new SavingsBank();

        vm.prank(alice);
        carolBank.deposit{value: 5 ether}();

        uint256 carolBefore = carol.balance;
        vm.prank(carol);
        carolBank.emergencyWithdraw();

        assertEq(carolBank.getTotalBalance(), 0, "Contract should be drained");
        assertEq(carol.balance - carolBefore, 5 ether, "Owner should receive funds");
    }

    /// @notice Non-owner cannot call emergencyWithdraw
    function test_NonOwnerCannotEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: ONE_ETH}();

        vm.prank(alice);
        vm.expectRevert(SavingsBank.OnlyOwner.selector);
        bank.emergencyWithdraw();
    }

    /// @notice Emergency withdraw emits event
    function test_EmergencyWithdrawEmitsEvent() public {
        // Deploy a fresh bank where carol is the owner
        vm.prank(carol);
        SavingsBank carolBank = new SavingsBank();

        vm.prank(alice);
        carolBank.deposit{value: ONE_ETH}();

        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdrawn(carol, ONE_ETH);
        vm.prank(carol);
        carolBank.emergencyWithdraw();
    }

    // ─────────────────────────────────────────────────────────────
    //  8. BONUS: Fuzz Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice Fuzz: any valid deposit amount is tracked correctly
    function testFuzz_DepositTrackedCorrectly(uint256 amount) public {
        amount = bound(amount, MIN_DEP, 5 ether);

        vm.deal(alice, amount);
        vm.prank(alice);
        bank.deposit{value: amount}();

        assertEq(bank.getBalanceOf(alice), amount);
        assertEq(bank.getTotalBalance(), amount);
    }

    /// @notice Fuzz: partial withdrawals always leave correct remaining balance
    function testFuzz_PartialWithdrawLeavesCorrectBalance(uint256 depositAmt, uint256 withdrawAmt) public {
        depositAmt = bound(depositAmt, MIN_DEP, 5 ether);
        withdrawAmt = bound(withdrawAmt, 1, depositAmt);

        vm.deal(alice, depositAmt);
        vm.startPrank(alice);
        bank.deposit{value: depositAmt}();
        bank.withdraw(withdrawAmt);
        vm.stopPrank();

        assertEq(bank.getBalanceOf(alice), depositAmt - withdrawAmt);
    }
}
