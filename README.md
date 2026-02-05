<picture>
	<source media="(prefers-color-scheme: dark)" srcset="https://i.imgur.com/oc7sWCV.png">
	<source media="(prefers-color-scheme: light)" srcset="https://i.imgur.com/oc7sWCV.png">
	<img alt="AI Doctor System banner showing ambulance and paramedic NPCs" src="https://i.imgur.com/oc7sWCV.png" style="width:100%;max-width:900px;">
</picture>

# gldnrmz-aidoc
AI Doctor System for FiveM. Provides an automated paramedic NPC and vehicle to revive players when EMS is unavailable. Designed for server owners and developers seeking a reliable, configurable fallback medical system.

---

## ✨ Features
- Automated paramedic NPC and ambulance vehicle
- Revives dead players when EMS is offline or unavailable
- Configurable costs, revive times, and emergency timeouts
- Emergency teleport to hospital if NPC cannot reach player
- Discord webhook logging for all major events
- Highly configurable via `config.lua`
- Optimized for performance and reliability
- Standalone, but requires `community_bridge` for framework abstraction

## 📦 Requirements
| Dependency         | Required | Link                                                                 |
|-------------------|----------|----------------------------------------------------------------------|
| community_bridge  | Yes      | [community_bridge](https://github.com/TheOrderFivem/community_bridge/releases)      |
| Discord Webhook   | Optional | [Discord Docs](https://discord.com/developers/docs/resources/webhook)|

> **Note:** `community_bridge` must start before this resource.

## ⚙️ Installation
1. Download and place this resource in your `[scripts]` folder.
2. Ensure `community_bridge` is installed and started before `gldnrmz-aidoc`.
3. Add the following to your `server.cfg`:
	 ```
	 ensure community_bridge
	 ensure gldnrmz-aidoc
	 ```
4. Configure settings in `config.lua` as needed.

## 🛠️ Configuration
All configuration is handled in `config.lua`.

Example:
```lua
Config.Debug = false
Config.Vehicle = "ambulance"
Config.Doctor = 0           -- Minimum EMS required online
Config.Price = 1000         -- Cost for AI Doc
Config.ReviveTime = 10      -- Revive time (seconds)
Config.TPTime = 60          -- Teleport time (seconds)
Config.EMSJobName = "ambulance"
Config.HospitalCoords = {
		vector4(100.77, -416.16, 40.25, 162.58),
}
Config.EmergencyTimeout = 120
Config.Webhook = {
		enabled = true,
		url = "YOUR_DISCORD_WEBHOOK_URL",
		botName = "AI Doctor Bot",
		color = 3447003,
		avatar = "https://i.imgur.com/your-avatar.png"
}
```

### Key Config Fields
| Field              | Type      | Description                                      |
|--------------------|-----------|--------------------------------------------------|
| Debug              | boolean   | Enable debug prints                              |
| Vehicle            | string    | Vehicle spawn name for AI doctor                 |
| Doctor             | integer   | Min EMS required online to block AI doc          |
| Price              | integer   | Cost for AI doc service                          |
| ReviveTime         | integer   | Time to revive (seconds)                         |
| TPTime             | integer   | Time before emergency teleport (seconds)         |
| EMSJobName         | string    | Job name for EMS online check                    |
| HospitalCoords     | vector4[] | Hospital teleport location(s)                    |
| EmergencyTimeout   | integer   | Max wait before forced hospital transport        |
| Webhook            | table     | Discord webhook config (see above)               |

## 📘 Advanced
**Webhook Logging:**
- All major events (help called, player healed, emergency transport) are logged to Discord if enabled.
- Customize webhook appearance in `Config.Webhook`.

**Jail Check:**
- Prevents use if player is jailed (see `Config.JailCheck`).

## ❗ Troubleshooting
| Issue                        | Cause                                 | Solution                                  |
|------------------------------|---------------------------------------|-------------------------------------------|
| AI doc not spawning          | Dependency not started                 | Ensure `community_bridge` is started first|
| No Discord logs              | Webhook misconfigured                  | Check `Config.Webhook.url`                |
| Not enough money error       | Player lacks funds                     | Lower `Config.Price` or add funds         |
| Not working in jail          | Jail check enabled                     | Set `Config.JailCheck.enabled = false`    |
| Debug info missing           | Debug disabled                         | Set `Config.Debug = true`                 |

## 📝 License / Usage
- For personal and community use only
- Do not sell, rebrand, or remove author credit
- Modifications allowed for private use
- Redistribution only with original credit and license

## 🙏 Credit
- Original Author: GLDNRMZ#8700 / HHFW / Sanriku / amrclake
- [community_bridge](https://github.com/GLDNRMZ/community_bridge) by GLDNRMZ

## 📄 License
Attribution required. Do not redistribute or sell without explicit permission. Keep all author credits intact.
