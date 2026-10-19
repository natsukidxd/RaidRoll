# DKP Bidding Increment Rules

This document describes the tiered bid increment system used by the Raid Roll addon when DKP mode is enabled (`RR_DKP_Enabled == true`).

## Where the Rules Live

| Function | File | Line |
|----------|------|------|
| `RR_GetNextBid(rollID)` — computes the next valid bid | `RaidRoll/RaidRoll_OnLoad.lua` | 1650 |
| `RR_IsValidBid(bid)` — validates a bid typed in chat | `RaidRoll/RaidRoll_OnLoad.lua` | 1619 |
| `RR_CanAffordNextBid(rollID)` — checks if player can afford next bid | `RaidRoll/RaidRoll_OnLoad.lua` | 1660 |
| Bid button click handler | `RaidRoll/RaidRoll_ExtraRollFrames.lua` | 253 |

## Current Increment Schedule

| Current Highest Bid | Increment | Valid Bid Examples |
|---------------------|-----------|--------------------|
| < 10 | Starting bid | 10 |
| 10 – 99 | +10 | 10, 20, 30 … 100 |
| 100 – 499 | +50 | 150, 200, 250 … 500 |
| 500 – 1,999 | +100 | 600, 700, 800 … 2,000 |
| 2,000 – 4,999 | +500 | 2,500, 3,000, 3,500 … 5,000 |
| 5,000+ | +1,000 | 6,000, 7,000, 8,000 … |

Boundary values fall into the **higher** tier. For example, a current bid of exactly `100` increments by `50` (not `10`).

## Code Reference

### RR_GetNextBid (RaidRoll_OnLoad.lua:1650)

```lua
function RR_GetNextBid(rollID)
    local current = RR_GetCurrentHighestBid(rollID)
    if current < 10 then return 10 end
    if current < 100 then return current + 10 end
    if current < 500 then return current + 50 end
    if current < 2000 then return current + 100 end
    if current < 5000 then return current + 500 end
    return current + 1000
end
```

### RR_IsValidBid (RaidRoll_OnLoad.lua:1619)

```lua
function RR_IsValidBid(bid)
    -- 10-100: +10 steps (10,20,30...)
    -- 100-500: +50 steps (150,200,250...)
    -- 500+: +100 steps (600,700,800...)
    if bid == nil then return false end
    if bid < 10 then return false end

    if bid <= 100 then
        return (bid % 10) == 0
    elseif bid <= 500 then
        return (bid % 50) == 0
    else
        return (bid % 100) == 0
    end
end
```

> **Note:** `RR_IsValidBid` currently only validates up to the `+100` tier (bids > 500 must be multiples of 100). If you extend `RR_GetNextBid` beyond 5,000 (e.g. +1,000 tier), you should update `RR_IsValidBid` to match so that bids like `6,000` are accepted from chat.

## Callers

- **Bid button click** (`RaidRoll_ExtraRollFrames.lua:261`): sends `RR_GetNextBid()` as a chat message when the player clicks "Bid".
- **Affordability check** (`RaidRoll_OnLoad.lua:1662`): `RR_CanAffordNextBid` compares the player's Net DKP against `RR_GetNextBid()` to enable/disable the bid button.
- **Chat bid parsing** (`RaidRoll_OnLoad.lua:795`): bare numbers typed in raid/party chat are validated with `RR_IsValidBid` before being recorded.

## Changing the Rules

1. Edit the tier boundaries and increments in `RR_GetNextBid` (`RaidRoll_OnLoad.lua:1650`).
2. Update `RR_IsValidBid` (`RaidRoll_OnLoad.lua:1619`) so chat-typed bids match the same tiers.
3. Optionally update the bid button tooltip in `RaidRoll_Command` (`RaidRoll_OnLoad.lua:1985`) if you want to display the increment schedule.

## Recent Change

The `+100` tier was split into two new tiers:
- `500 – 1,999`: increment by `100`
- `2,000 – 4,999`: increment by `500`
- `5,000+`: increment by `1,000`

Previously the final `return current + 100` applied to all bids ≥ 500.
