--------------------
------ CONFIG ------
--------------------
Config = {}

Config.Debug = false

Config.Vehicle = "ambulance"

Config.Doctor = 0           -- Minimum Amount of EMS on duty.
Config.Price = 1500         -- Cost for AI Doc Services
Config.ReviveTime = 10      -- Revive in seconds
Config.TPTime = 60          -- Teleprt Time in seconds

-- Hospital coordinates for emergency teleport
Config.HospitalCoords = {
    vector4(100.77, -416.16, 40.25, 162.58),
}
Config.EmergencyTimeout = 120  -- Time in seconds before emergency teleport (2 minutes)

-- Webhook Configuration
Config.Webhook = {
    enabled = true,
    url = "https://discord.com/api/webhooks/1413981193292091556/9WcU5EUMP1bz3nQ6vkI5JMtu68bPN_jBu7N5U6sI50v8Hc5K8fIKqhD34AuPW_i8QKPS",
    botName = "AI Doctor Bot",
    color = 3447003, -- Blue color
    avatar = "https://i.imgur.com/your-avatar.png" -- Optional avatar URL
}
