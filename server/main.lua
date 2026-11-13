local Bridge = exports['community_bridge']:Bridge()
local RESOURCE = GetCurrentResourceName()
local L = Config.Locale

-- Active calls, keyed by player server id. The server only charges and
-- revives players that have a session it created itself.
---@type table<number, { startedAt: number }>
local sessions = {}
---@type table<number, number>
local lastCall = {}

local function debugPrint(...)
    if Config.Debug then print('[gldnrmz-aidoc]', ...) end
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function getBalance(src, account)
    return tonumber(Bridge.Framework.GetAccountBalance(src, account)) or 0
end

local function canAfford(src)
    local price = Config.Price
    if price <= 0 then return true end
    return getBalance(src, 'cash') >= price or getBalance(src, 'bank') >= price
end

---Charges cash if it covers the price, otherwise bank.
---@return string? account charged, nil when free
local function charge(src)
    local price = Config.Price
    if price <= 0 then return nil end
    local account = getBalance(src, 'cash') >= price and 'cash' or 'bank'
    Bridge.Framework.RemoveAccountBalance(src, account, price)
    return account
end

local function countOnDutyEMS()
    local count = 0
    for _, job in ipairs(Config.EMSJobs) do
        local players = Bridge.Framework.GetPlayersByJob(job) or {}
        for i = 1, #players do
            local jobData = Bridge.Framework.GetPlayerJobData(players[i])
            if jobData and jobData.onDuty ~= false then
                count = count + 1
            end
        end
    end
    return count
end

local warnedDeadCheck = false
local function isDead(src)
    if not ServerConfig.VerifyDeadServerSide then return true end
    -- esx_ambulancejob sets state.isDead, wasabi_ambulance sets state.dead
    local bag = Player(src).state
    if bag.isDead or bag.dead then return true end
    local ok, dead = pcall(Bridge.Framework.GetIsPlayerDead, src)
    if not ok then
        -- Framework module doesn't support it: don't lock players out.
        if not warnedDeadCheck then
            warnedDeadCheck = true
            print('^3[gldnrmz-aidoc] Server-side dead check unavailable, set ServerConfig.VerifyDeadServerSide = false^0')
        end
        return true
    end
    return dead and true or false
end

local function isJailed(src)
    local jail = ServerConfig.JailCheck
    if not jail.enabled then return false end
    local ok, value = pcall(Bridge.Framework.GetPlayerMetadata, src, jail.key)
    if not ok or not value then return false end
    if type(value) == 'number' then return value > 0 end
    return value == true
end

local function getPlayerInfo(src)
    local first, last = Bridge.Framework.GetPlayerName(src)
    local jobData = Bridge.Framework.GetPlayerJobData(src) or {}
    return {
        source = src,
        playerName = GetPlayerName(src) or 'Unknown',
        charName = ('%s %s'):format(first or 'Unknown', last or ''),
        identifier = Bridge.Framework.GetPlayerIdentifier(src) or 'Unknown',
        job = jobData.jobLabel or jobData.jobName or 'Unemployed',
    }
end

local function depositSociety(amount)
    local society = ServerConfig.Society
    if not society.enabled or amount <= 0 then return false end
    local ok, result = pcall(ServerConfig.DepositSociety, society.account, amount, society.reason)
    if not ok or result == false then
        print(('^3[gldnrmz-aidoc] Society deposit to "%s" failed: %s^0'):format(society.account, tostring(result)))
        return false
    end
    return true
end

local function endSession(src)
    sessions[src] = nil
end

---Registers a callback that always answers the client, even if the handler
---errors (otherwise the client would wait on the response forever).
local function registerCallback(name, handler)
    Bridge.Callback.Register(name, function(src, ...)
        local result = table.pack(pcall(handler, src, ...))
        if not result[1] then
            print(('^1[gldnrmz-aidoc] %s errored: %s^0'):format(name, tostring(result[2])))
            endSession(src)
            return false
        end
        return table.unpack(result, 2, result.n)
    end)
end

--------------------------------------------------------------------------------
-- Availability
--------------------------------------------------------------------------------

---Checks whether a player may call the AI doctor right now.
---@param src number
---@return boolean ok
---@return string? reason player-facing message when not ok
local function checkAvailability(src)
    if sessions[src] then
        return false, L.already_called
    end

    if Config.Cooldown > 0 and lastCall[src] then
        local remaining = Config.Cooldown - (os.time() - lastCall[src])
        if remaining > 0 then
            return false, L.cooldown:format(remaining)
        end
    end

    if not isDead(src) then
        return false, L.not_dead
    end

    if isJailed(src) then
        return false, L.jailed
    end

    if countOnDutyEMS() > Config.MaxEMSOnline then
        return false, L.too_many_ems
    end

    if Config.RequireFunds and not canAfford(src) then
        return false, L.no_money:format(Config.Price)
    end

    return true
end

--------------------------------------------------------------------------------
-- Client callbacks / events
--------------------------------------------------------------------------------

registerCallback('gldnrmz-aidoc:server:request', function(src)
    local ok, reason = checkAvailability(src)
    if not ok then
        debugPrint(('request denied for %d: %s'):format(src, reason))
        return false, reason
    end

    sessions[src] = { startedAt = os.time() }
    lastCall[src] = os.time()
    debugPrint(('session started for %d'):format(src))

    local info = getPlayerInfo(src)
    Webhook.Send(
        '🚑 AI Doctor Called',
        ('**%s** requested AI doctor services.'):format(Webhook.Escape(info.charName)),
        ServerConfig.Webhook.colors.called,
        {
            Webhook.PlayerField('👤 Player', info),
            {
                name = '🚑 Service',
                value = ('**Price:** `$%d`\n**EMS on duty:** `%d`\n**Timeout:** `%ds`')
                    :format(Config.Price, countOnDutyEMS(), Config.EmergencyTimeout),
                inline = true,
            },
        }
    )

    return true
end)

---Called by the client when treatment finished ('treated') or the emergency
---timeout was reached ('transported'). The server validates the session and
---timing, then revives and charges.
registerCallback('gldnrmz-aidoc:server:complete', function(src, method, hospitalIndex)
    local session = sessions[src]
    if not session then return false end

    local elapsed = os.time() - session.startedAt
    local minimum
    if method == 'treated' then
        minimum = Config.ReviveTime
    elseif method == 'transported' then
        minimum = Config.EmergencyTimeout
    else
        return false
    end

    -- 2s tolerance for timer differences between client and server
    if elapsed + 2 < minimum then
        print(('^1[gldnrmz-aidoc] Player %d completed "%s" after %ds (min %ds), rejected^0')
            :format(src, method, elapsed, minimum))
        endSession(src)
        return false
    end

    if not isDead(src) then
        -- Revived by someone else meanwhile: nothing to do, don't charge.
        endSession(src)
        return false
    end

    if Config.RequireFunds and not canAfford(src) then
        endSession(src)
        return false, L.no_money:format(Config.Price)
    end

    local ok, result = pcall(ServerConfig.Revive, src)
    if not ok or result == false then
        print(('^1[gldnrmz-aidoc] ServerConfig.Revive failed for %d: %s^0'):format(src, tostring(result)))
        endSession(src)
        return false
    end

    local account = charge(src)
    local deposited = account and depositSociety(Config.Price) or false
    endSession(src)

    local hospital = Config.Hospitals[tonumber(hospitalIndex) or 1] or Config.Hospitals[1]
    local info = getPlayerInfo(src)
    local billing = {
        name = '💳 Billing',
        value = ('**Fee:** `$%d`\n**Paid from:** `%s`\n**Society:** `%s`')
            :format(Config.Price, account or 'free', deposited and ServerConfig.Society.account or 'no'),
        inline = true,
    }

    if method == 'treated' then
        Webhook.Send(
            '✅ Player Treated',
            ('**%s** was revived by the AI doctor after %ds.'):format(Webhook.Escape(info.charName), elapsed),
            ServerConfig.Webhook.colors.treated,
            { Webhook.PlayerField('👤 Patient', info), billing }
        )
    else
        Webhook.Send(
            '🚨 Emergency Transport',
            ('**%s** was transported to **%s** after the response timed out.')
                :format(Webhook.Escape(info.charName), hospital and hospital.label or 'hospital'),
            ServerConfig.Webhook.colors.transported,
            { Webhook.PlayerField('🆘 Patient', info), billing }
        )
    end

    -- Local server event other resources can listen to.
    TriggerEvent('gldnrmz-aidoc:server:serviceCompleted', src, method, account and Config.Price or 0)

    return true, Config.Price
end)

RegisterNetEvent('gldnrmz-aidoc:server:cancel', function(reason)
    local src = source
    if not sessions[src] then return end
    endSession(src)
    debugPrint(('session cancelled for %d (%s)'):format(src, tostring(reason)))

    local info = getPlayerInfo(src)
    Webhook.Send(
        '✖️ AI Doctor Cancelled',
        ('**%s**\'s call was cancelled: `%s`'):format(Webhook.Escape(info.charName), tostring(reason):sub(1, 64)),
        ServerConfig.Webhook.colors.cancelled,
        { Webhook.PlayerField('👤 Player', info) }
    )
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src] = nil
    lastCall[src] = nil
end)

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

---@param src number
---@return boolean
exports('IsPlayerInService', function(src)
    return sessions[tonumber(src)] ~= nil
end)

---@param src number
---@return boolean ok
---@return string? reason
exports('CanUseService', function(src)
    return checkAvailability(tonumber(src))
end)

---@return number
exports('GetOnDutyEMSCount', countOnDutyEMS)

---Cancels a player's active call and removes the ambulance (e.g. when real EMS takes over).
---@param src number
---@return boolean cancelled
exports('CancelService', function(src)
    src = tonumber(src)
    if not src or not sessions[src] then return false end
    endSession(src)
    TriggerClientEvent('gldnrmz-aidoc:client:cancel', src)
    return true
end)

--------------------------------------------------------------------------------
-- Version check
--------------------------------------------------------------------------------

local function parseVersion(v)
    local parts = {}
    for n in tostring(v):gmatch('%d+') do parts[#parts + 1] = tonumber(n) end
    return parts
end

---@return boolean true when `a` is newer than `b`
local function isNewer(a, b)
    local pa, pb = parseVersion(a), parseVersion(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

if ServerConfig.VersionCheck then
    CreateThread(function()
        local current = GetResourceMetadata(RESOURCE, 'version', 0) or '0.0.0'
        PerformHttpRequest('https://raw.githubusercontent.com/GLDNRMZ/gldnrmz-aidoc/main/version.txt', function(status, body)
            if status ~= 200 or not body then
                print(('^3[gldnrmz-aidoc] Unable to check for updates (HTTP %s)^0'):format(status))
                return
            end
            local latest = body:gsub('%s+', '')
            if latest ~= '' and isNewer(latest, current) then
                print(('^3[gldnrmz-aidoc] Update available: %s (current %s)^0'):format(latest, current))
            end
        end, 'GET')
    end)
end
