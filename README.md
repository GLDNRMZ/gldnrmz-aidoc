<img alt="AI Doctor System banner" src="https://i.imgur.com/oc7sWCV.png" style="width:100%;max-width:900px;">

# gldnrmz-aidoc
AI paramedic for FiveM. When a player is downed and too few EMS are on duty, `/help` sends an ambulance with an NPC crew who perform CPR and revive the player. If they can't reach the player in time, the player is transported to the nearest hospital.

Framework-agnostic through [community_bridge](https://github.com/TheOrderFivem/community_bridge) (QBCore, Qbox, ESX).

## Features
- NPC ambulance and crew drive to the player, walk over and perform CPR
- Stuck ambulances are moved next to the player, then the medic is placed beside them as a last resort
- Emergency transport to the nearest configured hospital after a timeout
- Server-authoritative: the server checks death state, jail, EMS count, funds and timing before charging or reviving
- Optional society payout (Renewed-Banking, qb-banking, okokBanking, fd_banking, tgiann-bank)
- Discord logging, configured server-side so the URL never reaches clients
- Exports for radial menus, EMS scripts and other resources

## Requirements
| Dependency       | Required |
|------------------|----------|
| community_bridge | Yes      |
| An ambulance/death script (wasabi_ambulance, qbx_medical, esx_ambulancejob, ...) | Yes |

## Installation
1. Place the resource in your resources folder.
2. In `server.cfg`, start it after `community_bridge` and set the webhook (optional):
   ```cfg
   ensure community_bridge
   ensure gldnrmz-aidoc

   # use `set`, not `setr` (setr sends the value to every client)
   set gldnrmz_aidoc_webhook "https://discord.com/api/webhooks/..."
   ```
3. Set your ambulance script's revive call in `server/config.lua` (`ServerConfig.Revive`).
4. Adjust `config.lua`.

## Configuration
| File | Sent to clients | Contains |
|------|-----------------|----------|
| `config.lua` | Yes | Command, prices, timings, models, hospitals, text |
| `server/config.lua` | No | Revive hook, jail check, society payout, webhook, version check |

### `config.lua`
| Field | Description |
|-------|-------------|
| `Command` | `{ name, description }`, or `false` to disable the chat command |
| `EMSJobs` | Jobs counted as EMS (on-duty only) |
| `MaxEMSOnline` | AI doctor is available while on-duty EMS ≤ this |
| `Cooldown` | Seconds between calls per player (0 = off) |
| `Price` | Service fee |
| `RequireFunds` | Refuse service when the player can't afford it |
| `ReviveTime` | CPR duration (s) |
| `TeleportTime` | Seconds before a stuck ambulance is moved to the player |
| `EmergencyTimeout` | Seconds before emergency transport to hospital |
| `Vehicle` | Model, plate, spawn distance, speed, driving style |
| `MedicModel` | Crew ped model |
| `Blip` | Ambulance blip settings |
| `Hospitals` | `{ label, coords = vector4 }` list, nearest is used |
| `Locale` | All player-facing text |

### `server/config.lua`
| Field | Description |
|-------|-------------|
| `Revive(src)` | Revives the player. Examples for wasabi, qb/qbx and esx are included |
| `VerifyDeadServerSide` | Check framework death state on the server |
| `JailCheck` | `{ enabled, key }`, framework metadata key |
| `Society` / `DepositSociety` | Pay the fee into a job account |
| `Webhook` | Bot name, images, footer, colours. URL comes from the `gldnrmz_aidoc_webhook` convar |
| `VersionCheck` | Print a notice when a newer version exists |

## Exports
### Client
```lua
exports['gldnrmz-aidoc']:RequestService()  -- same as /help, returns boolean
exports['gldnrmz-aidoc']:IsServiceActive() -- boolean
exports['gldnrmz-aidoc']:CancelService()   -- boolean
```

### Server
```lua
exports['gldnrmz-aidoc']:IsPlayerInService(src)   -- boolean
exports['gldnrmz-aidoc']:CanUseService(src)       -- ok, reason
exports['gldnrmz-aidoc']:GetOnDutyEMSCount()      -- number
exports['gldnrmz-aidoc']:CancelService(src)       -- boolean, e.g. when real EMS takes over
```

## Events
Server-side, local only (`AddEventHandler`, not net):
```lua
AddEventHandler('gldnrmz-aidoc:server:serviceCompleted', function(src, method, amountCharged)
    -- method: 'treated' | 'transported'
end)
```

## Troubleshooting
| Issue | Fix |
|-------|-----|
| "This can only be used when you are downed" while dead | Your ambulance script doesn't set framework death metadata: set `ServerConfig.VerifyDeadServerSide = false` |
| Player not revived | Set the correct call in `ServerConfig.Revive` |
| No Discord logs | Check the `gldnrmz_aidoc_webhook` convar and the server console for HTTP errors |
| Society not paid | Enable `ServerConfig.Society` and check `DepositSociety` matches your banking resource |
| Need more detail | `Config.Debug = true` |

## Credit
- Original authors: GLDNRMZ#8700 / HHFW / Sanriku / amrclake
- Attribution required. Do not redistribute or sell without explicit permission. Keep all author credits intact.
