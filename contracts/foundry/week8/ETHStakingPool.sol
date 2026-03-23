// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingPool {
    //  Stake Struct
    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

   
    address public owner;
    uint256 public rewardRate; // reward per second
    mapping(address => Stake) public stakes;

    
    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    //  stake
    function stake() public payable {
        require(msg.value > 0, "Cannot stake 0");
        require(stakes[msg.sender].amount == 0, "Already has active stake");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            claimed: false
        });
    }

    //  calculateReward
    function calculateReward(address _user) public view returns (uint256) {
        Stake storage userStake = stakes[_user];
        if (userStake.claimed || userStake.amount == 0) return 0;

        uint256 duration = block.timestamp - userStake.startTime;
        return duration * rewardRate;
    }

    // unstake
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

   
    receive() external payable {}
}