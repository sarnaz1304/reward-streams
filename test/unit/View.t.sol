// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "evc/EthereumVaultConnector.sol";
import "../harness/BaseRewardStreamsHarness.sol";
import {MockERC20} from "../utils/MockERC20.sol";
import {MockController} from "../utils/MockController.sol";

contract ViewTest is Test {
    EthereumVaultConnector internal evc;
    BaseRewardStreamsHarness internal distributor;

    function setUp() external {
        evc = new EthereumVaultConnector();
        distributor = new BaseRewardStreamsHarness(evc, 10 days);
    }

    function test_EnabledRewards(address account, address rewarded, uint8 n, bytes memory seed) external {
        n = uint8(bound(n, 1, 5));

        vm.startPrank(account);
        for (uint8 i = 0; i < n; i++) {
            address reward = address(uint160(uint256(keccak256(abi.encode(seed, i)))));
            distributor.enableReward(rewarded, reward);

            address[] memory enabledRewards = distributor.enabledRewards(account, rewarded);
            assertEq(enabledRewards.length, i + 1);
            assertEq(enabledRewards[i], reward);
        }
    }

    function test_BalanceOf(address account, address rewarded, uint256 balance) external {
        distributor.setAccountBalance(account, rewarded, balance);
        assertEq(distributor.balanceOf(account, rewarded), balance);
    }

    function test_RewardAmountCurrent(
        address rewarded,
        address reward,
        uint48 blockTimestamp,
        uint128 amount
    ) external {
        uint48 epoch = distributor.getEpoch(blockTimestamp);
        distributor.setDistributionAmount(rewarded, reward, epoch, amount);
        vm.warp(blockTimestamp);
        assertEq(distributor.rewardAmount(rewarded, reward), amount);
    }

    function test_RewardAmount(address rewarded, address reward, uint48 epoch, uint128 amount) external {
        distributor.setDistributionAmount(rewarded, reward, epoch, amount);
        assertEq(distributor.rewardAmount(rewarded, reward, epoch), amount);
    }

    function test_totalRewardedEligible(address rewarded, address reward, uint256 total) external {
        BaseRewardStreams.TotalsStorage memory totals;
        totals.totalEligible = total;

        distributor.setDistributionTotals(rewarded, reward, totals);
        assertEq(distributor.totalRewardedEligible(rewarded, reward), totals.totalEligible);
    }

    function test_totalRewardRegistered(address rewarded, address reward, uint128 total) external {
        BaseRewardStreams.TotalsStorage memory totals;
        totals.totalRegistered = total;

        distributor.setDistributionTotals(rewarded, reward, totals);
        assertEq(distributor.totalRewardRegistered(rewarded, reward), totals.totalRegistered);
    }

    function test_totalRewardClaimed(address rewarded, address reward, uint128 total) external {
        BaseRewardStreams.TotalsStorage memory totals;
        totals.totalClaimed = total;

        distributor.setDistributionTotals(rewarded, reward, totals);
        assertEq(distributor.totalRewardClaimed(rewarded, reward), totals.totalClaimed);
    }

    function test_Epoch(uint48 timestamp) external {
        vm.assume(timestamp < type(uint48).max - distributor.EPOCH_DURATION());
        vm.warp(timestamp);

        assertEq(distributor.getEpoch(timestamp), distributor.currentEpoch());
        assertEq(distributor.currentEpoch(), timestamp / distributor.EPOCH_DURATION());
        assertEq(
            distributor.getEpochStartTimestamp(distributor.currentEpoch()),
            distributor.currentEpoch() * distributor.EPOCH_DURATION()
        );
        assertEq(
            distributor.getEpochEndTimestamp(distributor.currentEpoch()),
            distributor.getEpochStartTimestamp(distributor.currentEpoch()) + distributor.EPOCH_DURATION()
        );
    }

    function test_EpochHasntStarted_TimeElapsedInEpoch(
        uint48 epoch,
        uint48 lastUpdated,
        uint256 blockTimestamp
    ) external {
        epoch = uint48(bound(epoch, 1, type(uint48).max / distributor.EPOCH_DURATION()));
        blockTimestamp = bound(blockTimestamp, 0, distributor.getEpochStartTimestamp(epoch) - 1);
        lastUpdated = uint48(bound(lastUpdated, 0, blockTimestamp));

        vm.warp(blockTimestamp);
        assertEq(distributor.timeElapsedInEpoch(epoch, lastUpdated), 0);
    }

    function test_EpochIsOngoing_TimeElapsedInEpoch(
        uint48 epoch,
        uint48 lastUpdated,
        uint256 blockTimestamp
    ) external {
        epoch = uint48(bound(epoch, 1, type(uint48).max / distributor.EPOCH_DURATION()));
        blockTimestamp = bound(
            blockTimestamp, distributor.getEpochStartTimestamp(epoch), distributor.getEpochEndTimestamp(epoch) - 1
        );
        lastUpdated = uint48(bound(lastUpdated, 0, blockTimestamp));

        vm.warp(blockTimestamp);

        if (lastUpdated > distributor.getEpochStartTimestamp(epoch)) {
            assertEq(distributor.timeElapsedInEpoch(epoch, lastUpdated), block.timestamp - lastUpdated);
        } else {
            assertEq(
                distributor.timeElapsedInEpoch(epoch, lastUpdated),
                block.timestamp - distributor.getEpochStartTimestamp(epoch)
            );
        }
    }

    function test_EpochHasEnded_TimeElapsedInEpoch(uint48 epoch, uint48 lastUpdated, uint256 blockTimestamp) external {
        epoch = uint48(bound(epoch, 1, type(uint48).max / distributor.EPOCH_DURATION()));
        blockTimestamp = bound(blockTimestamp, distributor.getEpochEndTimestamp(epoch), type(uint48).max);
        lastUpdated = uint48(bound(lastUpdated, 0, distributor.getEpochEndTimestamp(epoch)));

        vm.warp(blockTimestamp);

        if (lastUpdated > distributor.getEpochStartTimestamp(epoch)) {
            assertEq(
                distributor.timeElapsedInEpoch(epoch, lastUpdated),
                distributor.getEpochEndTimestamp(epoch) - lastUpdated
            );
        } else {
            assertEq(distributor.timeElapsedInEpoch(epoch, lastUpdated), distributor.EPOCH_DURATION());
        }
    }

    function test_msgSender(address caller) external {
        vm.assume(caller != address(0) && caller != address(evc));

        vm.startPrank(caller);
        assertEq(distributor.msgSender(), caller);

        vm.startPrank(caller);
        bytes memory result =
            evc.call(address(distributor), caller, 0, abi.encodeWithSelector(distributor.msgSender.selector));
        assertEq(abi.decode(result, (address)), caller);
    }
}
