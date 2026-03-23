// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SavingsBank
 * @author You
 * @notice A simple savings bank contract where users can deposit and withdraw ETH
 * @dev Includes bonus features: minimum deposit, withdrawal cooldown, and owner emergency withdraw
 */
contract SavingsBank {
    // ─────────────────────────────────────────────────────────────
    //  State Variables
    // ─────────────────────────────────────────────────────────────

    address public owner;

    /// @notice Minimum ETH required per deposit (0.001 ETH)
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    /// @notice Cooldown period between withdrawals (60 seconds)
    uint256 public constant WITHDRAWAL_COOLDOWN = 60 seconds;

    /// @notice Tracks each user's ETH balance
    mapping(address => uint256) private balances;

    /// @notice Tracks the last withdrawal timestamp per user
    mapping(address => uint256) private lastWithdrawalTime;

    // ─────────────────────────────────────────────────────────────
    //  Events
    // ─────────────────────────────────────────────────────────────

    /// @notice Emitted when a user deposits ETH
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when the owner performs an emergency withdrawal
    event EmergencyWithdrawn(address indexed owner, uint256 amount);

    // ─────────────────────────────────────────────────────────────
    //  Errors
    // ─────────────────────────────────────────────────────────────

    error BelowMinimumDeposit(uint256 sent, uint256 minimum);
    error InsufficientBalance(uint256 requested, uint256 available);
    error CooldownNotExpired(uint256 remainingSeconds);
    error OnlyOwner();
    error TransferFailed();
    error ZeroAmount();

    // ─────────────────────────────────────────────────────────────
    //  Modifiers
    // ─────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // ─────────────────────────────────────────────────────────────
    //  Constructor
    // ─────────────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────────────────────
    //  External / Public Functions
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Deposit ETH into your savings account
     * @dev Must send at least MIN_DEPOSIT (0.001 ETH)
     */
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        if (msg.value < MIN_DEPOSIT) {
            revert BelowMinimumDeposit(msg.value, MIN_DEPOSIT);
        }

        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH from your savings account
     * @param amount The amount of ETH (in wei) to withdraw
     * @dev Subject to a 60-second cooldown between withdrawals
     */
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(amount, balances[msg.sender]);
        }

        // ── Bonus: Withdrawal cooldown check ──
        uint256 lastTime = lastWithdrawalTime[msg.sender];
        if (lastTime != 0) {
            uint256 elapsed = block.timestamp - lastTime;
            if (elapsed < WITHDRAWAL_COOLDOWN) {
                revert CooldownNotExpired(WITHDRAWAL_COOLDOWN - elapsed);
            }
        }

        // Effects before interactions (Checks-Effects-Interactions pattern)
        balances[msg.sender] -= amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;

        emit Withdrawn(msg.sender, amount);

        // Interaction
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Returns the caller's current balance
     */
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @notice Returns the balance of any given address
     * @param user The address to check
     */
    function getBalanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @notice Returns the total ETH held by the contract
     */
    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the timestamp of the user's last withdrawal
     * @param user The address to check
     */
    function getLastWithdrawalTime(address user) external view returns (uint256) {
        return lastWithdrawalTime[user];
    }

    // ─────────────────────────────────────────────────────────────
    //  Bonus: Owner Emergency Withdraw
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Owner-only emergency function to drain the contract
     * @dev Only callable by the contract owner in emergencies
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert ZeroAmount();

        emit EmergencyWithdrawn(owner, contractBalance);

        (bool success,) = payable(owner).call{value: contractBalance}("");
        if (!success) revert TransferFailed();
    }

    // ─────────────────────────────────────────────────────────────
    //  Fallback — reject accidental ETH transfers
    // ─────────────────────────────────────────────────────────────

    receive() external payable {
        revert("Use deposit() to send ETH");
    }
}
