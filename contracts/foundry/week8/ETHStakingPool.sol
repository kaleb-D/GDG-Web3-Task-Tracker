// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingPool {
    // STEP 1: Stake Struct
    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    // STEP 2: State Variables
    address public owner;
    uint256 public rewardRate; // reward per second
    mapping(address => Stake) public stakes;

    // STEP 3: Constructor
    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    // STEP 4: stake
    function stake() public payable {
        require(msg.value > 0, "Cannot stake 0");
        require(stakes[msg.sender].amount == 0, "Already has active stake");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            claimed: false
        });
    }

    // STEP 5: calculateReward
    function calculateReward(address _user) public view returns (uint256) {
        Stake storage userStake = stakes[_user];
        if (userStake.claimed || userStake.amount == 0) return 0;

        uint256 duration = block.timestamp - userStake.startTime;
        return duration * rewardRate;
    }

    // STEP 6: unstake
    function unstake() public {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        require(!userStake.claimed, "Already unstaked");

        uint256 reward = calculateReward(msg.sender);
        uint256 totalPayout = userStake.amount + reward;

        userStake.claimed = true;
        userStake.amount = 0; // Reset for safety

        payable(msg.sender).transfer(totalPayout);
    }

    // Helper to fund the contract with reward ETH
    receive() external payable {}
}