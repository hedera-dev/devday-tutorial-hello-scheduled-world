// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {
    HederaScheduleService
} from "@hashgraph/smart-contracts/contracts/system-contracts/hedera-schedule-service/HederaScheduleService.sol";
import {HederaResponseCodes} from "@hashgraph/smart-contracts/contracts/system-contracts/HederaResponseCodes.sol";

/**
 * @title HelloScheduledWorld
 * @author Hedera Developer Relations
 * @notice A simple demo of Hedera's on-chain cron jobs via HSS (HIP-1215)
 * @dev Demonstrates scheduling recurring messages without off-chain bots
 *
 * Key concept: On traditional EVM chains, contracts cannot "wake up" on their own.
 * Hedera's Schedule Service changes this—contracts can schedule future calls to themselves!
 */
contract HelloScheduledWorld is HederaScheduleService {
    uint256 constant GAS_LIMIT = 2_000_000;

    string public message;
    uint256 public interval;
    bool public isActive;

    event MessagePrinted(string message, uint256 timestamp);

    constructor() payable {}
    receive() external payable {}

    function scheduleMessage(string calldata _message, uint256 _interval) external {
        message = _message;
        interval = _interval;
        isActive = true;
        _schedule(block.timestamp + _interval);
    }

    function printMessage() external {
        require(isActive, "Not active");
        emit MessagePrinted(message, block.timestamp);
        _schedule(block.timestamp + interval);
    }

    function stopScheduling() external {
        isActive = false;
    }

    function _schedule(uint256 time) internal {
        bytes memory data = abi.encodeWithSelector(this.printMessage.selector);
        (int64 responseCode,) = scheduleCall(address(this), time, GAS_LIMIT, 0, data);
        require(responseCode == HederaResponseCodes.SUCCESS, "Schedule failed");
    }
}
