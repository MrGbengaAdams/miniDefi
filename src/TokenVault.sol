// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenVault is Ownable {
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    uint256 public constant REWARD_RATE = 100;
    mapping(address => uint256) public lastUpdate;

    uint256 public totalStaked;
    ERC20 public MiniToken;

    error TokenVault__InsufficientStakes();

    constructor(address _tokenAddress) Ownable(msg.sender) {
        MiniToken = ERC20(_tokenAddress);
    }

    function stake(uint256 amount) public {
        MiniToken.transferFrom(msg.sender, address(this), amount);

        if (stakes[msg.sender] > 0) {
            uint256 pendingRewards = calculateRewards(msg.sender);
            rewards[msg.sender] += pendingRewards;
        }

        stakes[msg.sender] += amount;
        totalStaked += amount;
        lastUpdate[msg.sender] = block.number;
    }

    function unstake(uint256 amount) public {
        uint256 availableStakes = stakes[msg.sender];
        if (amount > availableStakes) {
            revert TokenVault__InsufficientStakes();
        }

        uint256 pendingRewards = calculateRewards(msg.sender);
        rewards[msg.sender] += pendingRewards;
        MiniToken.transfer(msg.sender, amount);
        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        lastUpdate[msg.sender] = block.number;
    }

    function getUserStake(address user) public view returns (uint256) {
        uint256 availableStakes = stakes[user];
        return availableStakes;
    }

    function calculateRewards(address user) public view returns (uint256) {
        uint256 blockPassed = block.number - lastUpdate[user];
        uint256 rewardsEarned = blockPassed * REWARD_RATE;
        return rewardsEarned;
    }

    function claimRewards() public {
        uint256 rewardsEarned = calculateRewards(msg.sender);
        uint256 totalEarned = rewardsEarned + rewards[msg.sender];

        if (rewardsEarned == 0) {
            revert TokenVault__InsufficientStakes();
        }
        MiniToken.transfer(msg.sender, totalEarned);
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.number;
    }

    function withdrawStuckTokens(address _token, address _to) public onlyOwner {
        ERC20 token = ERC20(_token);

        uint256 balance = token.balanceOf(address(this));

        token.transfer(_to, balance);
    }
}
