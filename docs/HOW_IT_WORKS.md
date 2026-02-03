# How Hello Scheduled World Works

## The Traditional EVM Problem

On Ethereum and most EVM chains, smart contracts are **passive**:

```
Contract sits idle
    ↓
Waiting for external transaction
    ↓
No transaction = No execution
```

For recurring tasks, you need:

- Chainlink Keepers ($$$)
- Gelato Network ($$$)
- Custom off-chain bots (complexity)

## Hedera's Solution

The **Hedera Schedule Service (HSS)** lets contracts schedule their own future calls:

```
Contract calls HSS.scheduleCall()
    ↓
HSS stores the schedule on-chain
    ↓
Network executes at specified time
    ↓
Contract can schedule NEXT call
    ↓
Self-sustaining loop!
```

## Code Walkthrough

### 1. The HSS Call

```solidity
function _schedule(uint256 time) internal {
    bytes memory data = abi.encodeWithSelector(this.printMessage.selector);
    (int64 responseCode,) = scheduleCall(
        address(this),  // to: this contract
        time,           // when: unix timestamp
        GAS_LIMIT,      // gasLimit: 2 million
        0,              // value: 0 HBAR
        data            // what: printMessage()
    );
    require(responseCode == HederaResponseCodes.SUCCESS, "Schedule failed");
}
```

### 2. The Self-Scheduling Loop

```solidity
function printMessage() external {
    require(isActive, "Not active");

    // 1. Do the work
    emit MessagePrinted(message, block.timestamp);

    // 2. Schedule next execution (THE KEY PART!)
    _schedule(block.timestamp + interval);
}
```

When `printMessage()` runs, it schedules the **next** `printMessage()`.

### 3. The Timeline

```
Time 0:00 - User calls scheduleMessage("Hello", 15)
         → Contract schedules printMessage() for 0:15

Time 0:15 - Network executes printMessage()
         → Emits "Hello"
         → Schedules printMessage() for 0:30

Time 0:30 - Network executes printMessage()
         → Emits "Hello"
         → Schedules printMessage() for 0:45

... continues until stopped or out of HBAR
```

## HBAR Requirement

The contract pays gas for scheduled executions:

```
Contract Balance: 5 HBAR
Each execution: ~0.01 HBAR
≈ 500 executions before empty
```

Send more HBAR anytime:

```bash
cast send $CONTRACT_ADDRESS --value 5ether --rpc-url $HEDERA_RPC_URL --private-key $HEDERA_PRIVATE_KEY
```

## Advanced: Capacity-Aware Scheduling

The `HelloScheduledAirdrop` contract uses `hasScheduleCapacity()` to check if a time slot is available:

```solidity
function _findAvailableSecond(uint256 expiry) internal returns (uint256) {
    // Try the exact desired time first
    if (hasScheduleCapacity(expiry, GAS_LIMIT)) {
        return expiry;
    }

    // Exponential backoff with jitter
    bytes32 seed = getPseudorandomSeed();
    for (uint256 i = 0; i < MAX_PROBES; i++) {
        uint256 baseDelay = 1 << i; // 1, 2, 4, 8, 16...
        bytes32 hash = keccak256(abi.encodePacked(seed, i));
        uint256 jitter = uint256(uint16(uint256(hash))) % (baseDelay + 1);
        uint256 candidate = expiry + baseDelay + jitter;

        if (hasScheduleCapacity(candidate, GAS_LIMIT)) {
            return candidate;
        }
    }

    return expiry + (1 << MAX_PROBES);
}
```

This prevents scheduling failures when time slots are busy.

## Security Notes

**Q: Can someone create an infinite loop?**  
A: No. HSS requires scheduled time to be strictly in the future. Plus, each execution costs gas.

**Q: Can anyone trigger the scheduled call early?**  
A: No. Only Hedera network executes at the scheduled time.

**Q: What if time slot is full?**  
A: Use `hasScheduleCapacity()` to find available slots (see HelloScheduledAirdrop).

## Comparison: Traditional vs Hedera

| Feature                 | Traditional EVM | Hedera HSS |
| ----------------------- | --------------- | ---------- |
| External bots needed    | ✅ Yes          | ❌ No      |
| Infrastructure cost     | $$$             | Just gas   |
| Single point of failure | ✅ Yes          | ❌ No      |
| Truly decentralized     | ❌ No           | ✅ Yes     |
| On-chain cron jobs      | ❌ Impossible   | ✅ Native  |
