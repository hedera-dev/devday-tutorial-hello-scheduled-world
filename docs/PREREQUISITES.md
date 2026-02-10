# Workshop Prerequisites: Hello Scheduled World

> In this workshop you will deploy smart contracts to Hedera Testnet and interact with them using Foundry's `forge` and `cast` CLI tools. Please complete **all** of the steps below **before** the workshop so we can dive straight into the code.

---

## 1. System Requirements

You need a Unix-like terminal environment:

- **macOS** — Terminal or iTerm2
- **Linux** — Any terminal emulator
- **Windows** — WSL2 (Windows Subsystem for Linux) is **required**. Native PowerShell/CMD will not work reliably with `source .env` and the Foundry toolchain. Install WSL2 via `wsl --install` in an admin PowerShell, then work inside the WSL2 Ubuntu terminal for everything below.

You also need **Git** installed (`git --version` to verify).

---

## 2. Install Foundry

Foundry provides `forge` (build/test/deploy) and `cast` (send transactions and read contract state), both of which are used throughout the workshop.

```bash
# Install foundryup (the Foundry toolchain installer)
curl -L https://foundry.paradigm.xyz | bash

# Follow the on-screen instructions to add foundryup to your PATH,
# then install/update the toolchain:
foundryup
```

### Verify the installation

```bash
forge --version
cast --version
```

Both commands should return version info. The contracts use **Solidity 0.8.33**, so make sure you have a recent Foundry release (January 2026 or later). If you installed Foundry previously, run `foundryup` again to update.

> **Troubleshooting**: If `foundryup` is not found after install, open a new terminal or run `source ~/.bashrc` (or `~/.zshrc`).

---

## 3. Create a Hedera Testnet Account

You need an **ECDSA** account on Hedera Testnet with testnet HBAR.

1. Go to [portal.hedera.com](https://portal.hedera.com)
2. Sign up or log in
3. Create a **Testnet** account — when prompted for key type, select **ECDSA**
4. Once created, locate and copy your **HEX-encoded private key** (it starts with `0x`)
5. Your account will be automatically funded with testnet HBAR

> **Important**: You must select **ECDSA** (not ED25519). Foundry and the EVM-compatible RPC endpoint require ECDSA keys.

### Verify your account has funds

You can check your balance on [HashScan](https://hashscan.io/testnet) by searching for your account ID (e.g., `0.0.XXXXX`). You should have testnet HBAR available. The workshop contracts need roughly **15–20 HBAR** total to deploy and run (5 HBAR for the simple contract, 10 HBAR for the advanced one, plus gas).

If you need more testnet HBAR, use the faucet at [portal.hedera.com](https://portal.hedera.com) to top up.

---

## 4. Clone the Repository and Install Dependencies

```bash
git clone https://github.com/hedera-dev/devday-tutorial-hello-scheduled-world.git
cd devday-tutorial-hello-scheduled-world
```

Install the Solidity dependencies (forge-std, OpenZeppelin, Hedera smart contracts):

```bash
forge install
```

This pulls three git submodules into `lib/`:

| Dependency               | Version     | Purpose                        |
| ------------------------ | ----------- | ------------------------------ |
| `forge-std`              | v1.14.0     | Foundry test framework         |
| `openzeppelin-contracts` | v5.5.0      | ERC20, Ownable                 |
| `hedera-smart-contracts` | main branch | HSS system contract interfaces |

### Verify dependencies installed

```bash
ls lib/
# Should show: forge-std  hedera-smart-contracts  openzeppelin-contracts
```

---

## 5. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your private key:

```bash
# .env
HEDERA_RPC_URL=https://testnet.hashio.io/api
HEDERA_PRIVATE_KEY=0xYOUR_ECDSA_PRIVATE_KEY_HERE
```

Then load the variables into your shell:

```bash
source .env
```

### Verify your RPC connection and key

```bash
# Check that cast can reach Hedera Testnet
cast chain-id --rpc-url $HEDERA_RPC_URL
# Expected output: 296 (Hedera Testnet chain ID)

# Check your account balance (derive address from your private key)
cast balance $(cast wallet address --private-key $HEDERA_PRIVATE_KEY) --rpc-url $HEDERA_RPC_URL
# Should return a non-zero value (in wei — divide by 10^18 for HBAR)
```

If `cast chain-id` fails, check your internet connection and firewall settings. The RPC endpoint `https://testnet.hashio.io/api` must be reachable.

---

## 6. Compile the Contracts

```bash
forge build
```

This should compile successfully with no errors. Foundry will auto-download Solidity 0.8.33 if not already cached.

Expected output:

```
[⠊] Compiling...
[⠊] Compiling X files with solc 0.8.33
[⠊] Solc 0.8.33 finished in X.XXs
Compiler run successful!
```

> **Troubleshooting**: If you see import resolution errors, make sure `forge install` completed successfully and that `lib/` contains all three dependency directories.

---

## 7. Run the Tests (Optional but Recommended)

```bash
forge test
```

All tests should pass. This validates your entire setup end-to-end:

```
[PASS] test_InitialBalance() (gas: ...)
[PASS] test_InitialState() (gas: ...)
[PASS] test_ReceiveHBAR() (gas: ...)
[PASS] test_RevertWhen_PrintNotActive() (gas: ...)
[PASS] test_StopWhenNotActive() (gas: ...)
...
```

> **Note**: These tests run locally against a Foundry test VM, not against Hedera Testnet. The HSS system contract calls (`scheduleCall`, `hasScheduleCapacity`) are not available in the local VM, so the tests cover everything except the scheduling interactions themselves — those you'll see live during the workshop.

---

## Pre-Workshop Checklist

Before arriving, confirm each of these:

- [ ] Unix-like terminal available (macOS/Linux, or WSL2 on Windows)
- [ ] Git installed
- [ ] Foundry installed and up to date (`forge --version` works)
- [ ] Hedera Testnet account created with **ECDSA** key type
- [ ] Account has testnet HBAR (15+ HBAR recommended)
- [ ] Repository cloned and dependencies installed (`forge install`)
- [ ] `.env` configured with your private key
- [ ] `cast chain-id --rpc-url $HEDERA_RPC_URL` returns `296`
- [ ] `forge build` compiles with no errors

---

## What We'll Cover in the Workshop

1. **HelloScheduledWorld** — Deploy a contract that schedules recurring "Hello Hedera!" messages using Hedera's Schedule Service (HSS / HIP-1215), no off-chain bots needed
2. **HelloScheduledAirdrop** — Deploy an ERC20 token with automated scheduled airdrops, random recipient selection via Hedera PRNG, and capacity-aware scheduling
3. **Interacting via `cast`** — Send transactions, read state, and watch events on HashScan
4. **Contract verification** — Verify your deployed contracts on HashScan using the metadata generation script

---

## Resources

- [HIP-1215: Generalized Scheduled Contract Calls](https://hips.hedera.com/hip/hip-1215)
- [Foundry Book](https://book.getfoundry.sh)
- [Hedera Portal](https://portal.hedera.com) — Account management and faucet
- [HashScan (Testnet)](https://hashscan.io/testnet) — Block explorer
- [Hedera JSON-RPC Relay (Hashio)](https://swirldslabs.com/hashio/) — The RPC endpoint used in this workshop
