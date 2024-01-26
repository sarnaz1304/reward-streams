// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "../../src/StakingFreeRewardStreams.sol";

contract StakingFreeRewardStreamsHarness is StakingFreeRewardStreams {
    using SafeERC20 for IERC20;
    using Set for SetStorage;

    constructor(IEVC evc, uint40 epochDuration) StakingFreeRewardStreams(evc, epochDuration) {}

    function setBucket(address rewarded, address reward, uint40 epoch, uint128 bucket) external {
        buckets[rewarded][reward][_bucketStorageIndex(epoch)][_bucketEpochIndex(epoch)] = bucket;
    }

    function getDistribution(address rewarded, address reward) external view returns (DistributionStorage memory) {
        return distribution[rewarded][reward];
    }

    function setDistribution(
        address rewarded,
        address reward,
        DistributionStorage calldata distributionStorage
    ) external {
        distribution[rewarded][reward] = distributionStorage;
    }

    function getTotals(address rewarded, address reward) external view returns (TotalsStorage memory) {
        return totals[rewarded][reward];
    }

    function setTotals(address rewarded, address reward, TotalsStorage calldata totalsStorage) external {
        totals[rewarded][reward] = totalsStorage;
    }

    function getBalance(address account, address rewarded) external view returns (uint256) {
        return balances[account][rewarded];
    }

    function setBalance(address account, address rewarded, uint256 balance) external {
        balances[account][rewarded] = balance;
    }

    function getRewards(address account, address rewarded) external view returns (address[] memory) {
        return rewards[account][rewarded].get();
    }

    function insertReward(address account, address rewarded, address reward) external {
        rewards[account][rewarded].insert(reward);
    }

    function getEarned(address account, address rewarded, address reward) external view returns (EarnStorage memory) {
        return earned[account][rewarded][reward];
    }

    function setEarned(address account, address rewarded, address reward, EarnStorage calldata earnStorage) external {
        earned[account][rewarded][reward] = earnStorage;
    }
}
