--------------------
------ CONFIG ------
--------------------
Config = {}

Config.Debug = false

Config.Vehicle = "ambulance"

Config.Doctor = 0           -- Minimum Amount of EMS on duty.
Config.Price = 1000         -- Cost for AI Doc Services
Config.ReviveTime = 10      -- Revive in seconds
Config.TPTime = 60          -- Teleprt Time in seconds
Config.EMSJobName = "ambulance" -- Job name used for EMS online checks

Config.AmbulanceScript = function(src)
    -- TriggerClientEvent("hospital:client:Revive", src) -- qb-ambulancejob / qbx-ambulancejob
    -- TriggerClientEvent("esx_ambulancejob:revive", src) -- esx_ambulancejob
    TriggerClientEvent("wasabi_ambulance:revive", src)
end

Config.JailCheck = {
    enabled = false, -- Enable if your framework exposes jail metadata
    key = "injail"
}

Config.AddToSociety = false -- Requires a supported management/banking resource in community_bridge
Config.ServiceAccount = "ambulance"

Config.HospitalCoords = {
    vector4(100.77, -416.16, 40.25, 162.58),
}
Config.EmergencyTimeout = 120  -- Time in seconds before emergency teleport (2 minutes)

Config.Webhook = {
    enabled = true,
    url = "https://discord.com/api/webhooks/1468209435603111980/GYKEomRfE1coZIPQ61CrEKRPJzP35yJul0E4ztOZ8ZGhvzm73Lng3p8TPYpr4caOG0mc",
    botName = "AI Doctor Bot",
    color = 3447003, -- Blue color
    avatar = "https://i.imgur.com/your-avatar.png" -- Optional avatar URL
}
