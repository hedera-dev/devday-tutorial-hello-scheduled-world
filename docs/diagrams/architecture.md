# Architecture Diagrams

## Hello Scheduled World Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    HELLO SCHEDULED WORLD                      │
└──────────────────────────────────────────────────────────────┘

     USER                    CONTRACT                    HSS (0x16b)
       │                        │                            │
       │  scheduleMessage()     │                            │
       │───────────────────────>│                            │
       │                        │                            │
       │                        │  scheduleCall(printMessage)│
       │                        │───────────────────────────>│
       │                        │                            │
       │                        │     (stored on-chain)      │
       │                        │                            │
       │                        │                            │
       │     ═══════════════════════════════════════════     │
       │     ║     INTERVAL SECONDS PASS...            ║     │
       │     ═══════════════════════════════════════════     │
       │                        │                            │
       │                        │  AUTOMATIC EXECUTION       │
       │                        │<───────────────────────────│
       │                        │                            │
       │                        │ emit MessagePrinted()      │
       │                        │                            │
       │                        │  scheduleCall(printMessage)│
       │                        │───────────────────────────>│
       │                        │                            │
       │                        │     (next iteration)       │
       │                        │                            │
       │     ═══════════════════════════════════════════     │
       │     ║     LOOP CONTINUES FOREVER...           ║     │
       │     ═══════════════════════════════════════════     │
```

## State Machine

```
         ┌─────────────┐
         │   IDLE      │
         │ isActive=F  │
         └──────┬──────┘
                │ scheduleMessage()
                ▼
         ┌─────────────┐
    ┌───>│   ACTIVE    │<────┐
    │    │ isActive=T  │     │
    │    └──────┬──────┘     │
    │           │            │
    │           │ (time)     │
    │           ▼            │
    │    ┌─────────────┐     │
    │    │ printMessage│─────┘
    │    │  (auto)     │ schedules next
    │    └──────┬──────┘
    │           │ stopScheduling()
    │           ▼
    │    ┌─────────────┐
    └────│   STOPPED   │
         │ isActive=F  │
         └─────────────┘
```

## Traditional vs Hedera

```
TRADITIONAL EVM                          HEDERA HSS
═══════════════                          ══════════

  Contract                                Contract
     │                                       │
     │ (waits)                               │ scheduleCall()
     │                                       │──────────────────>HSS
     │                                       │
  External Bot ──────> Contract           Network ──────> Contract
     │                    │                  │                │
     │                    │                  │                │
  (repeat)             (repeat)           (automatic)    (schedules next)


  ❌ Needs bot                            ✅ Self-contained
  ❌ Single point of failure              ✅ Decentralized
  ❌ Extra costs                          ✅ Just gas fees
```
