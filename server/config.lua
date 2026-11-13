--------------------------------------------------------------------------------
-- Server-only config. Not sent to clients.
--------------------------------------------------------------------------------
ServerConfig = {}

-- How the player is revived once treatment finishes. Runs on the server.
-- Return false to signal failure (the player is not charged).
-- Auto-detects the common ambulance scripts; replace it if yours isn't listed.
ServerConfig.Revive = function(src)
    if GetResourceState('wasabi_ambulance') == 'started' then
        TriggerClientEvent('wasabi_ambulance:revive', src)       -- wasabi_ambulance
    elseif GetResourceState('esx_ambulancejob') == 'started' then
        TriggerClientEvent('esx_ambulancejob:revive', src)       -- esx_ambulancejob
    elseif GetResourceState('qbx_medical') == 'started' or GetResourceState('qb-ambulancejob') == 'started' then
        TriggerClientEvent('hospital:client:Revive', src)        -- qbx_medical / qb-ambulancejob
    else
        return exports.community_bridge:Framework().RevivePlayer(src) -- community_bridge default for your framework
    end
    return true
end

-- Verify on the server that the player is actually downed before serving them.
-- Uses community_bridge (framework metadata) plus the isDead / dead state bags
-- set by esx_ambulancejob and wasabi_ambulance. Disable only if your ambulance
-- script sets none of these.
ServerConfig.VerifyDeadServerSide = true

-- Block service for jailed players. Reads framework metadata `key` on the server.
-- (qb/qbx: 'injail' holds remaining jail time, so any value above 0 counts as jailed.)
ServerConfig.JailCheck = {
    enabled = false,
    key = 'injail',
}

-- Pay the service fee into a society/job account.
ServerConfig.Society = {
    enabled = false,
    account = 'ambulance',
    reason = 'AI Doctor Service',
}

-- Deposit function used when Society.enabled = true.
-- Auto-detects common banking resources; replace it if yours isn't listed.
ServerConfig.DepositSociety = function(account, amount, reason)
    if GetResourceState('Renewed-Banking') == 'started' then
        return exports['Renewed-Banking']:addAccountMoney(account, amount)
    elseif GetResourceState('qb-banking') == 'started' then
        return exports['qb-banking']:AddMoney(account, amount, reason)
    elseif GetResourceState('okokBanking') == 'started' then
        return exports['okokBanking']:AddMoney(account, amount)
    elseif GetResourceState('fd_banking') == 'started' then
        return exports['fd_banking']:AddMoney(account, amount, reason)
    elseif GetResourceState('tgiann-bank') == 'started' then
        return exports['tgiann-bank']:AddJobMoney(account, amount)
    end
    return false
end

-- Discord logging.
-- Put the URL in server.cfg instead of here so it never ends up in git:
--   set gldnrmz_aidoc_webhook "https://discord.com/api/webhooks/..."
-- (use `set`, NOT `setr` - `setr` replicates the value to clients)
ServerConfig.Webhook = {
    enabled = true,
    url = GetConvar('gldnrmz_aidoc_webhook', ''),
    botName = 'AI Doctor',
    avatar = nil,                                    -- optional image URL
    thumbnail = 'https://i.imgur.com/oc7sWCV.png',   -- optional image URL
    footer = 'AI Doctor System | Your Server',
    colors = {
        called = 15158332,      -- red
        treated = 3066993,      -- green
        transported = 15105570, -- orange
        cancelled = 9807270,    -- grey
    },
}

-- Print a notice on start if a newer version is published on GitHub.
ServerConfig.VersionCheck = true
