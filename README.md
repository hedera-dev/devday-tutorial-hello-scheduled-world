# Hello Scheduled World

**A hands-on tutorial showcasing Hedera's on-chain cron jobs!**

On traditional EVM chains, smart contracts cannot "wake up" on their own. **Hedera changes this.** With [HSS (HIP-1215)](https://hips.hedera.com/hip/hip-1215), contracts can schedule future calls to themselves—no off-chain bots required!

## What's Inside

| Contract                    | Purpose                       | Complexity             |
| --------------------------- | ----------------------------- | ---------------------- |
| `HelloScheduledWorld.sol`   | Simple scheduled messages     | ⭐ Minimal (~50 lines) |
| `HelloScheduledAirdrop.sol` | ERC20 with scheduled airdrops | ⭐⭐⭐ Advanced        |

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Hedera Testnet account from [portal.hedera.com](https://portal.hedera.com)

### Setup

```bash
# Clone & setup
git clone https://github.com/hedera-dev/devday-tutorial-hello-scheduled-world.git
cd devday-tutorial-hello-scheduled-world
forge install
cp .env.example .env
# Edit .env with your HEDERA_PRIVATE_KEY

# Load environment variables
source .env
```

### HelloScheduledWorld (Simple)

```bash
# Deploy with 5 HBAR funding
forge create src/HelloScheduledWorld.sol:HelloScheduledWorld \
  --rpc-url $HEDERA_RPC_URL \
  --broadcast \
  --private-key $HEDERA_PRIVATE_KEY \
  --value 5ether

# Save the deployed address
export CONTRACT_ADDRESS=0x...

# Start scheduling "Hello Hedera!" every 15 seconds
cast send $CONTRACT_ADDRESS \
  'scheduleMessage(string,uint256)' 'Hello Hedera!' 15 \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY

# Watch events on HashScan
# https://hashscan.io/testnet/contract/<CONTRACT_ADDRESS>

# Stop scheduling
cast send $CONTRACT_ADDRESS \
  'stopScheduling()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

### HelloScheduledAirdrop (Advanced)

```bash
# Deploy with 10 HBAR funding (name, symbol, initial supply)
forge create src/HelloScheduledAirdrop.sol:HelloScheduledAirdrop \
  --rpc-url $HEDERA_RPC_URL \
  --broadcast \
  --private-key $HEDERA_PRIVATE_KEY \
  --value 10ether \
  --constructor-args "Airdrop Token" "ADT" 1000000000000000000000000

# Save the deployed address
export TOKEN_ADDRESS=0x...

# Register for airdrop
cast send $TOKEN_ADDRESS \
  'registerForAirdrop()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY

# Start airdrop (100 tokens, every 20 seconds, 5 drops max)
cast send $TOKEN_ADDRESS \
  'startAirdrop(uint256,uint256,uint256,string)' \
  100000000000000000000 20 5 'Congrats on your airdrop!' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY

# Check status
cast call $TOKEN_ADDRESS 'getStatus()' --rpc-url $HEDERA_RPC_URL

# Stop airdrop
cast send $TOKEN_ADDRESS \
  'stopAirdrop()' \
  --rpc-url $HEDERA_RPC_URL \
  --private-key $HEDERA_PRIVATE_KEY
```

## Running Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/HelloScheduledWorld.t.sol -vvv
forge test --match-path test/HelloScheduledAirdrop.t.sol -vvv

# Run specific test function
forge test --match-test test_Register -vvv
```

## Documentation

- **[docs/GUIDE.md](docs/GUIDE.md)** - Step-by-step tutorial (start here!)
- **[docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md)** - Technical deep-dive

## Resources

- [HIP-1215](https://hips.hedera.com/hip/hip-1215) - Generalized Scheduled Contract Calls
- [Hedera Portal](https://portal.hedera.com) - Get testnet account
- [HashScan](https://hashscan.io/testnet) - Block explorer

## License

MIT