# Raid Roll

A World of Warcraft addon for performing raid rolls, DKP bidding, and loot tracking.

## Project Structure

```
raidroll/
├── README.md                          # This file
├── BIDDING_RULES.md                   # DKP bidding increment rules documentation
├── CODE_STRUCTURE.md                  # Code layout and module reference
├── RaidRoll/                          # Core addon module
│   ├── RaidRoll.toc                   # Table of contents / manifest
│   ├── RaidRoll.xml                   # UI frame definitions
│   ├── RaidRoll_OnLoad.lua            # Core logic (3009 lines) — bid validation, increment math, roll handling
│   ├── RaidRoll_ExtraRollFrames.lua   # Bid/roll button UI and bid button click handler (863 lines)
│   ├── RaidRoll_OptionsMenu.lua       # Options panel (701 lines)
│   ├── RaidRoll_DKP.lua               # DKP guild data helpers (63 lines)
│   ├── RaidRoll_LDB.lua               # LDB data broker launcher (80 lines)
│   ├── Locale/                        # Localization files (en, de, fr, ru, es, cn, tw)
│   ├── Images/                        # Texture assets (TGA)
│   └── libs/                          # Embedded libraries (LibStub, CallbackHandler, LibDataBroker)
├── RaidRoll_DKP/                      # DKP tracking sub-module
│   ├── RaidRoll_DKP.toc
│   └── RaidRoll_DKP.lua               # Personal QDKP functions (252 lines)
└── RaidRoll_LootTracker/              # Loot tracking sub-module
    ├── RaidRoll_LootTracker.toc
    └── RaidRoll_LootTracker.lua       # Loot panel and display (1805 lines)
```

## Quick Facts

- **Game:** World of Warcraft (Interface 30300, compatible with 40000)
- **Author:** Musou (killerpet@gmail.com)
- **Language:** Lua
- **Total code:** ~7,300 lines across 8 Lua modules + XML UI
- **Saved variables:** `RaidRoll_DB`, `RaidRoll_DBPC` (account-wide + per-character)

## Key Entry Points

| File | Purpose | Key Functions |
|------|---------|---------------|
| `RaidRoll_OnLoad.lua` | Core engine — chat parsing, roll validation, bid math, winner determination | `RaidRoll_Event`, `RR_ARollHasOccured`, `RR_GetNextBid`, `RR_IsValidBid`, `RR_FindWinner`, `RR_Command` |
| `RaidRoll_ExtraRollFrames.lua` | Bid / Roll button UI | `RR_Roll_RollButton` OnClick handler |
| `RaidRoll_OptionsMenu.lua` | Configuration panel | `Setup_RR_Panel` |
| `RaidRoll_DKP.lua` (core) | Guild DKP data sync | `RR_GetDKPGuildData`, `RR_GetDKPCharacterData` |
| `RaidRoll_DKP/RaidRoll_DKP.lua` | Personal QDKP (quest DKP) | `RR_GetPersonalQDKP`, `RR_SetPersonalQDKP` |
| `RaidRoll_LootTracker/` | Boss loot window | `RaidRoll_LootPanel_Setup`, `RR_LootButton` |

## Bidding Increment Rules

See [`BIDDING_RULES.md`](./BIDDING_RULES.md) for the full tiered increment schedule, validation logic, and the recent change.

## How Bidding Works (DKP Mode)

1. Player types a bare number in raid/party chat (e.g. `150`).
2. `RaidRoll_Event` intercepts `CHAT_MSG_RAID` / `CHAT_MSG_PARTY` messages when `RR_DKP_Enabled` is true.
3. `RR_IsValidBid(bid)` checks the number against the tiered increment rules.
4. `RR_GetNextBid(rollID)` computes the next valid bid above the current highest.
5. The bid button in `RaidRoll_ExtraRollFrames.lua` sends `RR_GetNextBid()` as a chat message when clicked.
6. `RR_FindWinner()` determines the highest valid bidder when the roll closes.

## Contributing

Changes to bid increments should be made in `RR_GetNextBid()` inside `RaidRoll_OnLoad.lua` (around line 1650). Matching validation rules live in `RR_IsValidBid()` just above it (around line 1619).
