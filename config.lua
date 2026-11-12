--------------------------------------------------------------------------------
-- Shared config. This file is sent to every client, so never put secrets here.
-- Server-only settings (webhook, revive hook, society payout) are in server/config.lua.
--------------------------------------------------------------------------------
Config = {}

Config.Debug = false

-- Chat command players use while downed. Set to false to disable it and use
-- the client export instead: exports['gldnrmz-aidoc']:RequestService()
Config.Command = {
    name = 'help',
    description = 'Call a local paramedic',
}

-- Availability
Config.EMSJobs = { 'ambulance' } -- Jobs counted as EMS (only on-duty players count)
Config.MaxEMSOnline = 0          -- AI doctor works only while on-duty EMS count is at or below this
Config.Cooldown = 0              -- Seconds a player must wait between calls (0 = off)

-- Billing
Config.Price = 1000
Config.RequireFunds = false      -- true: refuse service when the player can't afford it from cash or bank
                                 -- false: always serve; charges cash if possible, otherwise bank

-- Timings (seconds)
Config.ReviveTime = 10           -- CPR / progress bar duration
Config.TeleportTime = 60         -- If the ambulance hasn't arrived by now, it is moved next to the player
Config.EmergencyTimeout = 120    -- If treatment hasn't finished by now, the player is taken to hospital

-- Ambulance and crew
Config.Vehicle = {
    model = 'ambulance',
    plate = 'AIDOC',
    spawnDistance = 60.0,        -- How far away the ambulance spawns (roughly)
    driveSpeed = 20.0,           -- m/s
    drivingStyle = 524863,
}
Config.MedicModel = 's_m_m_paramedic_01'

Config.Blip = {
    enabled = true,
    colour = 5,
    flash = true,
}

-- Emergency transport destinations. The nearest one to the player is used.
Config.Hospitals = {
    { label = 'Pillbox Medical Center', coords = vector4(100.77, -416.16, 40.25, 162.58) },
}

-- Player-facing text
Config.Locale = {
    not_dead          = 'This can only be used when you are downed',
    jailed            = "This can't be used while in jail",
    already_called    = "You've already called for help, please be patient",
    too_many_ems      = 'There are too many medics on duty',
    no_money          = 'You cannot afford the paramedic ($%d)',
    cooldown          = 'Please wait %d seconds before calling again',
    on_the_way        = 'A paramedic is on the way',
    progress_label    = 'Hang in there, buddy!',
    treated           = 'Your treatment is done, you were charged $%d',
    transported       = 'Emergency services transported you to %s',
    cancelled         = 'The paramedic call was cancelled',
    spawn_failed      = 'No paramedic could reach you, please try again',
}
