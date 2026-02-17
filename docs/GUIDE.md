# Step-by-Step Guide: Hello Scheduled World

This guide walks you through building a smart contract that schedules its own execution on Hedera—from scratch.

## Prerequisites

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Get a Hedera Testnet Account

1. Go to [portal.hedera.com](https://portal.hedera.com)
2. Create an account (select **ECDSA** key type)
3. Copy your **HEX-encoded private key** (starts with `0x`)

---

## Part 1: Project Setup

### Step 1.1: Create Project Directory

```bash
mkdir devday-tutorial-hello-scheduled-world
cd devday-tutorial-hello-scheduled-world
```

### Step 1.2: Initialize Foundry Project

```bash
forge init
```

This creates:

```
├── src/           # Smart contracts
├── script/        # Deployment scripts
├── test/          # Tests
├── lib/           # Dependencies
└── foundry.toml   # Configuration
```

### Step 1.3: Configure Foundry

Edit `foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
  "forge-std/=lib/forge-std/src/",
  "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
  "@hashgraph/smart-contracts/=lib/hedera-smart-contracts/"
]

[rpc_endpoints]
testnet = "${HEDERA_RPC_URL}"
```

### Step 1.4: Create Environment File

Create `.env`:

```bash
HEDERA_RPC_URL=https://testnet.hashio.io/api
HEDERA_PRIVATE_KEY=0x-your-private-key-here
```

Load it:

```bash
source .env
```

### Step 1.5: Install Dependencies

```bash
forge install hashgraph/hedera-smart-contracts@main
```

---

## Part 2: Understanding HSS

Before coding, let's understand what we're building.

### The Problem

On Ethereum/traditional EVMs:

- Contracts can't "wake up" on their own
- Need external bots (Chainlink Keepers, Gelato) to trigger functions
- Costs money, adds complexity, centralization risk

### Hedera's Solution

The **Hedera Schedule Service (HSS)** at address `0x16b` lets contracts:

- Schedule future calls to any contract (including themselves!)
- The network automatically executes at the specified time
- No external infrastructure needed

### Key Function: `scheduleCall`

```solidity
scheduleCall(
    address to,           // Contract to call
    uint256 expirySecond, // When to execute (unix timestamp)
    uint256 gasLimit,     // Gas for the call
    uint64 value,         // HBAR to send (usually 0)
    bytes callData        // Function to call (encoded)
) returns (int64 responseCode, address scheduleAddress)
```

- Returns `22` on success
- Selector: `0x6f5bfde8`

---

## Part 3: Write the Contract

### Step 3.1: Create the Contract File

Delete the default `src/Counter.sol` and create `src/HelloScheduledWorld.sol`:

```solidity
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
```

### Step 3.2: Understand the Code

**State Variables:**

- `message` - What to print
- `interval` - Seconds between prints
- `isActive` - Whether we're running

**Functions:**

- `scheduleMessage()` - Start the loop
- `printMessage()` - Called by the network, schedules next call
- `stopScheduling()` - Stop the loop
- `_schedule()` - Internal helper to call HSS

**The Magic Loop:**

```
User calls scheduleMessage("Hello", 15)
    ↓
Contract schedules printMessage() for 15 seconds later
    ↓
Network executes printMessage()
    ↓
printMessage() schedules NEXT printMessage() for 15 seconds later
    ↓
Loop continues forever (until stopped or out of HBAR)
```

### Step 3.3: Compile

```bash
forge build
```

---

## Part 4: Deploy to Hedera Testnet

### Step 4.1: Deploy

```bash
forge create src/HelloScheduledWorld.sol:HelloScheduledWorld \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY \
  --value 5ether
```

**Note:** We send 5 HBAR (`5 ether` in wei) to fund scheduled executions.

### Step 4.2: Save the Address

```bash
export CONTRACT_ADDRESS=0x...  # Your actual address
```

### Step 4.3: Verify the Contract

Download the metadata generation script:

```bash
curl -O https://gist.githubusercontent.com/kpachhai/972d63c5f5ecd9bbc718ab4dd34d5f29/raw/generate_hedera_sc_metadata.sh
chmod +x generate_hedera_sc_metadata.sh
```

Run the script to generate the bundles:

```bash
./generate_hedera_sc_metadata.sh HelloScheduledWorld
```

This produces a directory (e.g., verify-bundles/) containing a single metadata.json file for each contract.

Upload the following file to Hashscan's verification page:

- `verify-bundles/HelloScheduledWorld/metadata.json`

---

## Part 5: Start Scheduling

### Step 5.1: Call scheduleMessage

```bash
cast send $CONTRACT_ADDRESS \
  'scheduleMessage(string,uint256)' 'Hello Hedera!' 15 \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

This tells the contract to print "Hello Hedera!" every 15 seconds.

### Step 5.2: Watch on HashScan

1. Open: `https://hashscan.io/testnet/contract/<CONTRACT_ADDRESS>`
2. Click the **Events** tab
3. Watch `MessagePrinted` events appear every ~15 seconds!

---

## Part 6: Verify It's Working

### Check State

```bash
# Is it active?
cast call $CONTRACT_ADDRESS 'isActive()' --rpc-url $HEDERA_RPC_URL

# What's the message?
cast call $CONTRACT_ADDRESS 'message()' --rpc-url $HEDERA_RPC_URL

# What's the interval?
cast call $CONTRACT_ADDRESS 'interval()' --rpc-url $HEDERA_RPC_URL

# Contract balance (for gas)
cast balance $CONTRACT_ADDRESS --rpc-url $HEDERA_RPC_URL
```

---

## Part 7: Stop Scheduling

```bash
cast send $CONTRACT_ADDRESS \
  'stopScheduling()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

Events will stop appearing on HashScan.

---

## Part 8: Add More HBAR (If Needed)

Each scheduled execution costs gas. If the contract runs out:

```bash
cast send $CONTRACT_ADDRESS \
  --value 5ether \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

---

## Part 9: Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run only HelloScheduledWorld tests
forge test --match-path test/HelloScheduledWorld.t.sol -vvv
```

---

## Summary

You've built an **autonomous smart contract** that:

1. ✅ Schedules its own future execution
2. ✅ Runs indefinitely without external triggers
3. ✅ Uses only ~50 lines of Solidity
4. ✅ Requires no off-chain infrastructure

**This is impossible on Ethereum!** Hedera's HSS enables true on-chain automation.

---

## Part 10: HelloScheduledAirdrop (Advanced)

The `HelloScheduledAirdrop.sol` contract demonstrates a real-world use case: an ERC20 token with automated airdrops.

### Features

- Users register for airdrops
- Admin starts scheduled minting
- Random recipients selected using Hedera's PRNG
- Uses `hasScheduleCapacity()` for reliable scheduling
- Stops automatically after N distributions

### Deploy

```bash
forge create src/HelloScheduledAirdrop.sol:HelloScheduledAirdrop \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY \
  --value 10ether \
  --constructor-args "Airdrop Token" "ADT" 1000000000000000000000000

export TOKEN_ADDRESS=0x...
```

### Verify the Contract

Download the metadata generation script:

```bash
curl -O https://gist.githubusercontent.com/kpachhai/972d63c5f5ecd9bbc718ab4dd34d5f29/raw/generate_hedera_sc_metadata.sh
chmod +x generate_hedera_sc_metadata.sh
```

Run the script to generate the bundles:

```bash
./generate_hedera_sc_metadata.sh HelloScheduledAirdrop
```

This produces a directory (e.g., verify-bundles/) containing a single metadata.json file for each contract.

Upload the following file to Hashscan's verification page:

- `verify-bundles/HelloScheduledAirdrop/metadata.json`

### Register for Airdrop

```bash
cast send $TOKEN_ADDRESS \
  'registerForAirdrop()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

### Start Airdrop

```bash
# Parameters: amount (100 tokens), interval (20 seconds), maxDrops (5), message
cast send $TOKEN_ADDRESS \
  'startAirdrop(uint256,uint256,uint256,string)' \
  100000000000000000000 20 5 'Congrats on your airdrop!' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

### Check Status

```bash
# Get full status
cast call $TOKEN_ADDRESS 'getStatus()' --rpc-url $HEDERA_RPC_URL

# Get registered recipients
cast call $TOKEN_ADDRESS 'getRecipients()' --rpc-url $HEDERA_RPC_URL

# Check token balance
cast call $TOKEN_ADDRESS 'balanceOf(address)' <ADDRESS> --rpc-url $HEDERA_RPC_URL
```

### Stop Airdrop

```bash
cast send $TOKEN_ADDRESS \
  'stopAirdrop()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

### Add More HBAR

```bash
cast send $TOKEN_ADDRESS \
  --value 10ether \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

### Run Airdrop Tests

```bash
forge test --match-path test/HelloScheduledAirdrop.t.sol -vvv
```

---

## Next Steps

- Read [docs/HOW_IT_WORKS.md](HOW_IT_WORKS.md) for technical details
- Try modifying the contracts for your own use cases
