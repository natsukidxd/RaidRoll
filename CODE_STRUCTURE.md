# Code Structure Reference

Raid Roll is a World of Warcraft addon written in Lua (~7,300 lines total). It is split into a core module and two optional sub-modules.

## Module Overview

| Module | Path | Lines | Role |
|--------|------|-------|------|
| Core | `RaidRoll/` | ~4,650 | Roll engine, DKP bidding, UI frames, options |
| DKP sub-module | `RaidRoll_DKP/` | ~250 | Personal QDKP tracking |
| Loot Tracker sub-module | `RaidRoll_LootTracker/` | ~1,800 | Boss loot window & distribution |

### `RaidRoll/` (Core)

| File | Size | Purpose |
|------|------|---------|
| `RaidRoll.toc` | 18 | Addon manifest, library load order |
| `RaidRoll.xml` | 514 | UI frame/window definitions (XML) |
| `RaidRoll_OnLoad.lua` | 3,009 | **Core engine** — chat parsing, roll validation, bid math, winner determination, slash commands |
| `RaidRoll_ExtraRollFrames.lua` | 863 | Bid/Roll button UI, extra roll frames, loot awarding |
| `RaidRoll_OptionsMenu.lua` | 701 | Configuration options panel |
| `RaidRoll_DKP.lua` | 63 | Guild DKP data sync helpers |
| `RaidRoll_LDB.lua` | 80 | LibDataBroker launcher / options toggle |

### `RaidRoll_DKP/` (Sub-module)

| File | Size | Purpose |
|------|------|---------|
| `RaidRoll_DKP.toc` | 10 | Sub-module manifest (depends on RaidRoll) |
| `RaidRoll_DKP.lua` | 252 | Personal QDKP (quest DKP) get/set functions |

### `RaidRoll_LootTracker/` (Sub-module)

| File | Size | Purpose |
|------|------|---------|
| `RaidRoll_LootTracker.toc` | 11 | Sub-module manifest (depends on RaidRoll) |
| `RaidRoll_LootTracker.lua` | 1,805 | Loot panel, item sorting, display refresh, announcements |

### `RaidRoll/libs/` (Embedded Libraries)

- `LibStub/` — library versioning
- `CallbackHandler-1.0/` — event callback system
- `LibDataBroker-1.1/` — data broker launcher

## Key Function Index

### Core Engine (`RaidRoll_OnLoad.lua`)

| Function | Line | Description |
|----------|------|-------------|
| `RaidRoll_OnLoad` | 462 | Initialization on addon load |
| `RaidRoll_Event` | 617 | Main event handler (chat, system, roll messages) |
| `RR_ARollHasOccured` | 840 | Records a roll/bid for a player |
| `RR_IsValidBid` | 1619 | **Validates a DKP bid against increment rules** |
| `RR_GetCurrentHighestBid` | 1636 | Returns current highest bid for a roll ID |
| `RR_GetNextBid` | 1650 | **Computes the next valid bid increment** |
| `RR_CanAffordNextBid` | 1660 | Checks if player can afford the next bid |
| `RR_UpdateBidButtonState` | 1677 | Enables/disables the bid button |
| `RR_FindWinner` | 1691 | Determines the highest valid bidder |
| `RR_Display` | 1746 | Updates the roll display window |
| `RR_Command` | 1983 | Slash command handler (`/rr options`, etc.) |
| `RR_DoARaidRoll` | 2391 | Starts a raid roll |
| `RR_Roll` | 2563 | Performs a random roll |

### Bid / Roll Button (`RaidRoll_ExtraRollFrames.lua`)

| Function | Line | Description |
|----------|------|-------------|
| Button OnClick | 253 | Handles Bid/Roll button clicks; calls `RR_GetNextBid` in DKP mode |
| `RR_FinishRolling` | 668 | Announces winner and awards loot |
| `RR_GiveLoot` | 769 | Master looter loot assignment |

### DKP Data (`RaidRoll_DKP.lua`, core + sub-module)

| Function | File | Line | Description |
|----------|------|------|-------------|
| `RR_GetDKPGuildData` | `RaidRoll/RaidRoll_DKP.lua` | 1 | Syncs guild DKP data from officer notes |
| `RR_GetDKPCharacterData` | `RaidRoll/RaidRoll_DKP.lua` | 14 | Returns Net/Tot/Hrs for a character |
| `RR_GetPersonalQDKP` | `RaidRoll_DKP/RaidRoll_DKP.lua` | 15 | Gets personal quest DKP |
| `RR_SetPersonalQDKP` | `RaidRoll_DKP/RaidRoll_DKP.lua` | 23 | Sets personal quest DKP |

### Loot Tracker (`RaidRoll_LootTracker.lua`)

| Function | Line | Description |
|----------|------|-------------|
| `RaidRoll_LootPanel_Setup` | 5 | Initializes loot panel |
| `RR_SetupLootFrame` | 699 | Builds the loot UI frame |
| `RR_LootButton` | 1479 | Handles loot button clicks |
| `RR_AnnounceMsg` | 1586 | Sends loot announcement messages |

## QDKP Whisper Bot Listener (`RaidRoll_DKP/RaidRoll_DKP.lua:84`)

A hidden frame listens for `CHAT_MSG_WHISPER` messages from the external QDKP bot.
Only the player's own DKP is ever stored; replies about other players are ignored.

| Bot Message Format | Meaning | Stored? |
|--------------------|---------|---------|
| `You have $NET DKP ...` | Reply to `?dkp` (self) | Yes — line 100 |
| `$NAME has $NET DKP ...` | Reply to `?dkp $OTHERPLAYERNAME` | **No** — ignored (line 95) |
| `$AWARDSPENDTXT. Your new net DKP amount is $NET` | Successful bid | Yes — line 110 |
| `$AWARDSPENDTXT for $REASON. Your new net DKP amount is $NET` | Raid wipe / penalty | Yes — line 110 |
| `Your unuploaded changes have been cancelled. Your net DKP amount is $AMOUNT` | Officer reverted changes | Yes — line 119 |

Each stored amount calls `RR_SetPersonalQDKP()` then `RR_EnableDKPFromQDKP()`, which enables DKP mode, updates the bid button, refreshes the roll window, and persists to `RaidRoll_DBPC[player]["RR_DKP_Personal"]`.

## Data Flow: Placing a DKP Bid

1. Player types a number in raid chat OR clicks the Bid button.
2. `RaidRoll_Event` (`RaidRoll_OnLoad.lua:617`) intercepts the chat message.
3. `RR_IsValidBid` (`RaidRoll_OnLoad.lua:1619`) validates the number against tier rules.
4. `RR_ARollHasOccured` (`RaidRoll_OnLoad.lua:840`) records the bid.
5. `RR_GetNextBid` (`RaidRoll_OnLoad.lua:1650`) computes what the next bid should be.
6. `RR_FindWinner` (`RaidRoll_OnLoad.lua:1691`) picks the highest bidder at roll close.

## Data Flow: Addon Startup

1. `RaidRoll.toc` loads LibStub → CallbackHandler → LibDataBroker → `RaidRoll.xml` → `RaidRoll_OnLoad.lua`.
2. `RaidRoll_OnLoad` registers events and slash commands.
3. `RR_SetupVariables` initializes saved variables (`RaidRoll_DB`, `RaidRoll_DBPC`).
4. If DKP mode is on, `RR_GetDKPGuildData` syncs officer-note DKP values.

## Where to Make Common Changes

| Goal | File | Approximate Line |
|------|------|------------------|
| Change bid increments | `RaidRoll/RaidRoll_OnLoad.lua` | 1650 (`RR_GetNextBid`) |
| Change bid validation | `RaidRoll/RaidRoll_OnLoad.lua` | 1619 (`RR_IsValidBid`) |
| Change bid button behavior | `RaidRoll/RaidRoll_ExtraRollFrames.lua` | 253 (OnClick) |
| Add slash command | `RaidRoll/RaidRoll_OnLoad.lua` | 1983 (`RR_Command`) |
| Add option checkbox | `RaidRoll/RaidRoll_OptionsMenu.lua` | 3 (`Setup_RR_Panel`) |
| Add localization string | `RaidRoll/Locale/RaidRoll_Localization.en.lua` | — |
| Change UI layout | `RaidRoll/RaidRoll.xml` | — |
