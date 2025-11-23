# 🏥 AI Doctor System

A comprehensive AI Doctor script for FiveM QBCore servers that provides automated medical assistance to players when EMS is unavailable.

## 📋 Features

### Core Functionality
- **AI Doctor Service**: Automated medical response when EMS is offline or understaffed
- **Emergency Transport**: Automatic hospital transport if AI Doctor times out
- **Smart Payment System**: Supports both cash and bank payments
- **Professional NPCs**: Paramedic NPCs with realistic animations and speech
- **Vehicle System**: Ambulance with sirens and emergency lighting

### Enhanced Features
- **Discord Webhooks**: Real-time logging of all AI Doctor activities
- **Timeout Protection**: Emergency teleport to hospital after configurable timeout
- **Vehicle Detection**: Automatically exits vehicles before treatment
- **Anti-Spam**: Prevents multiple simultaneous calls
- **Job Integration**: Checks for on-duty EMS personnel

## 🚀 Installation

1. Download and extract to your resources folder
2. Add `ensure gldnrmz-aidoc` to your server.cfg
3. Configure settings in `config.lua`
4. Set up Discord webhook (optional)
5. Restart your server

## ⚙️ Configuration

### Basic Settings
```lua
Config.Debug = false              -- Enable debug mode
Config.Vehicle = "sandbulance"     -- AI Doctor vehicle model
Config.Doctor = 0                 -- Minimum EMS required to be on duty
Config.Price = 1000               -- Service cost
Config.ReviveTime = 10            -- Treatment time in seconds
Config.TPTime = 60                -- Teleport timeout in seconds
Config.EmergencyTimeout = 120     -- Emergency transport timeout
```

### Hospital Coordinates
```lua
Config.HospitalCoords = {
    vector4(100.77, -416.16, 40.25, 162.58), -- Pillbox Medical Center
}
```

## 🔗 Discord Webhook Setup

### Configuration
```lua
Config.Webhook = {
    enabled = true,
    url = "YOUR_DISCORD_WEBHOOK_URL_HERE",
    botName = "🏥 AI Doctor System",
    color = 3447003,
    avatar = "https://your-avatar-url.png"
}
```

### Creating a Discord Webhook
1. Go to your Discord server settings
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Choose the channel for notifications
5. Copy the webhook URL
6. Paste it in `config.lua`

### Webhook Events
The system logs three types of events:

| Event | Description | Color |
|-------|-------------|-------|
| 🚑 **AI Doctor Called** | Player uses `/help` command | Red |
| ✅ **Player Healed** | Successful treatment completion | Green |
| 🚨 **Emergency Transport** | Timeout emergency transport | Orange |

## 🎮 Usage

### Player Commands
- `/help` - Call AI Doctor (only when dead/downed)

### Requirements
- Player must be dead or in last stand
- Player cannot be in jail
- EMS on duty must be ≤ configured minimum
- Player must have sufficient funds

### Process Flow
1. Player uses `/help` command
2. System checks requirements
3. AI Doctor ambulance spawns and drives to player
4. Paramedic performs CPR animation
5. Player is revived after treatment time
6. Payment is processed
7. Ambulance departs

### Emergency Scenarios
- **Stuck Ambulance**: Auto-teleport to AI Doctor after 60 seconds
- **Critical Timeout**: Emergency hospital transport after 2 minutes
- **Vehicle Interference**: Automatic vehicle exit before treatment

## 🔧 Dependencies

- **QBCore Framework**
- **Renewed-Banking** (for ambulance fund deposits)
- **wasabi_ambulance** (for revive events)

## 📊 Logging

The script includes comprehensive logging:
- **QBCore Logs**: Command usage and outcomes
- **Discord Webhooks**: Rich embed notifications
- **Console Debug**: Optional debug information

## 🛠️ Customization

### Modifying Animations
```lua
local ANIM_DICT = "mini@cpr@char_a@cpr_str"
```

### Changing Vehicle
```lua
Config.Vehicle = "your_ambulance_model"
```

### Adjusting Timeouts
```lua
Config.TPTime = 60           -- Teleport to AI Doctor
Config.EmergencyTimeout = 120 -- Emergency hospital transport
```

## 🐛 Troubleshooting

### Common Issues

**Webhook not working:**
- Verify webhook URL is correct
- Check `enabled = true` in config
- Ensure Discord channel permissions

**AI Doctor not spawning:**
- Check EMS on duty count
- Verify player has sufficient funds
- Ensure player is dead/downed

**Vehicle stuck:**
- Wait for auto-teleport (60 seconds)
- Check for map conflicts
- Verify vehicle model exists

### Debug Mode
Enable debug mode for detailed console output:
```lua
Config.Debug = true
```

## 📝 Credits

- **Original QBCore Version**: [hhfw1](https://github.com/hhfw1/hh_aidoc)
- **Teleport Rework**: [Sanriku](https://github.com/Sanriku-Gaming)
- **Jail Integration**: amrclake
- **Enhanced Features**: GLDNRMZ#8700 / HHFW / Sanriku / amrclake

## 📄 License

This project is open source. Feel free to modify and distribute according to your server's needs.

## 🆘 Support

For support and updates, please refer to the original repository or contact the development team.

---

**Version**: Enhanced with Discord Webhooks  
**Compatible**: QBCore Framework  
**Last Updated**: 2024
