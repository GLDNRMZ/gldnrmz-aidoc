local Bridge = exports['community_bridge']:Bridge()


-- Webhook Function
local function SendWebhook(title, description, color, fields, thumbnail, author)
    if not Config.Webhook.enabled or not Config.Webhook.url or Config.Webhook.url == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or Config.Webhook.color,
            ["fields"] = fields or {},
            ["thumbnail"] = thumbnail and { ["url"] = thumbnail } or nil,
            ["author"] = author or nil,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            ["footer"] = {
                ["text"] = "🏥 AI Doctor System | Ascendant Roleplay",
                ["icon_url"] = "https://cdn.discordapp.com/emojis/692428843058724864.png"
            },
        }
    }
    
    local payload = {
        ["username"] = Config.Webhook.botName,
        ["avatar_url"] = Config.Webhook.avatar,
        ["embeds"] = embed
    }
    
    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

Bridge.Callback.Register('aidoc:docOnline', function(src)
	local doctor = 0
	local canpay = false
	local price = Config.Price or 0
	local cash = Bridge.Framework.GetAccountBalance(src, 'cash') or 0
	local bank = Bridge.Framework.GetAccountBalance(src, 'bank') or 0

	if cash >= price or bank >= price then
		canpay = true
	end

	local players = Bridge.Framework.GetPlayersByJob(Config.EMSJobName)
	for i = 1, #players do
		local jobData = Bridge.Framework.GetPlayerJobData(players[i])
		if jobData and (jobData.onDuty == nil or jobData.onDuty) then
			doctor = doctor + 1
		end
	end

	return doctor, canpay
end)

RegisterServerEvent('lb:charge')
AddEventHandler('lb:charge', function()
	local src = source
	local price = Config.Price or 0
	local cash = Bridge.Framework.GetAccountBalance(src, 'cash') or 0

	if cash >= price then
		Bridge.Framework.RemoveAccountBalance(src, 'cash', price)
	else
		Bridge.Framework.RemoveAccountBalance(src, 'bank', price)
	end

	if Config.AddToSociety and Bridge.Managment and Bridge.Managment.AddAccountMoney then
		Bridge.Managment.AddAccountMoney(Config.ServiceAccount, price, 'AI Doctor Service')
	end
end)

RegisterNetEvent('aidoc:server:revive', function()
	local src = source
	if type(Config.AmbulanceScript) == "function" then
		local ok, err = pcall(Config.AmbulanceScript, src)
		if ok then
			return
		end
		print("[gldnrmz-aidoc] Config.AmbulanceScript error: " .. tostring(err))
	end

	print("[gldnrmz-aidoc] No Config.AmbulanceScript set. Revive aborted.")
end)

local function GetPlayerInfo(src)
	local first, last = Bridge.Framework.GetPlayerName(src)
	local playerName = GetPlayerName(src) or 'Unknown'
	local charName = string.format("%s %s", first or "Unknown", last or "")
	local citizenid = Bridge.Framework.GetPlayerIdentifier(src) or 'Unknown'
	local jobData = Bridge.Framework.GetPlayerJobData(src) or {}
	local job = jobData.jobLabel or jobData.jobName or "Unemployed"
	local cash = Bridge.Framework.GetAccountBalance(src, 'cash') or 0
	local bank = Bridge.Framework.GetAccountBalance(src, 'bank') or 0
	return {
		playerName = playerName,
		charName = charName,
		citizenid = citizenid,
		job = job,
		cash = cash,
		bank = bank
	}
end

-- Webhook Events
RegisterServerEvent('aidoc:webhook:helpCalled')
AddEventHandler('aidoc:webhook:helpCalled', function()
	local src = source
	local info = GetPlayerInfo(src)
	
	local fields = {
		{
			["name"] = "👤 Player Information",
			["value"] = "```\n" .. info.playerName .. "```\n**Character:** " .. info.charName .. "\n**Citizen ID:** `" .. info.citizenid .. "`\n**Job:** " .. info.job,
			["inline"] = true
		},
		{
			["name"] = "🚑 Service Details",
			["value"] = "**Cost:** `$" .. Config.Price .. "`\n**Response Time:** `" .. Config.ReviveTime .. "s`\n**Timeout:** `" .. Config.EmergencyTimeout .. "s`",
			["inline"] = true
		},
	}
	
	local author = {
		["name"] = "Emergency Call Received",
		["icon_url"] = "https://cdn.discordapp.com/emojis/🚨.png"
	}
	
	SendWebhook(
		"🚑 AI Doctor Called",
		"**" .. info.charName .. "** requested AI Doctor services.",
		15158332, -- Red
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)

RegisterServerEvent('aidoc:webhook:playerHealed')
AddEventHandler('aidoc:webhook:playerHealed', function()
	local src = source
	local info = GetPlayerInfo(src)
	
	local fields = {
		{
			["name"] = "👤 Patient Information",
			["value"] = "```\n" .. info.playerName .. "```\n**Character:** " .. info.charName .. "\n**Citizen ID:** `" .. info.citizenid .. "`\n**Job:** " .. info.job,
			["inline"] = true
		},
		{
			["name"] = "💊 Treatment Summary",
			["value"] = "**Status:** `✅ Successfully Healed`\n**Method:** `AI Doctor Service`\n**Duration:** `" .. Config.ReviveTime .. " seconds`",
			["inline"] = true
		},
		{
			["name"] = "💳 Billing Information",
			["value"] = "**Service Fee:** `$" .. Config.Price .. "`\n**Payment:** `Processed`\n**Revenue Added:** `Ambulance Fund`",
			["inline"] = false
		}
	}
	
	local author = {
		["name"] = "Medical Treatment Complete",
		["icon_url"] = "https://cdn.discordapp.com/emojis/✅.png"
	}
	
	SendWebhook(
		"✅ Player Healed",
		"**" .. info.charName .. "** was successfully treated by AI Doctor.",
		3066993, -- Green
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)

RegisterServerEvent('aidoc:webhook:emergencyTransport')
AddEventHandler('aidoc:webhook:emergencyTransport', function()
	local src = source
	local info = GetPlayerInfo(src)
	
	local fields = {
		{
			["name"] = "🆘 Critical Patient",
			["value"] = "```\n" .. info.playerName .. "```\n**Character:** " .. info.charName .. "\n**Citizen ID:** `" .. info.citizenid .. "`\n**Job:** " .. info.job,
			["inline"] = true
		},
		{
			["name"] = "⚠️ Emergency Protocol",
			["value"] = "**Trigger:** `Response Timeout`\n**Duration:** `" .. Config.EmergencyTimeout .. " seconds`\n**Action:** `Hospital Transport`",
			["inline"] = true
		},
		{
			["name"] = "🏥 Transport Details",
			["value"] = "**Destination:** `Pillbox Medical Center`\n**Method:** `Emergency Teleport`\n**Status:** `Patient Stabilized`",
			["inline"] = false
		},
		{
			["name"] = "💰 Emergency Billing",
			["value"] = "**Emergency Fee:** `$" .. Config.Price .. "`\n**Payment Status:** `Processed`\n**Insurance:** `Not Covered`",
			["inline"] = false
		}
	}
	
	local author = {
		["name"] = "EMERGENCY TRANSPORT ACTIVATED",
		["icon_url"] = "https://cdn.discordapp.com/emojis/🚨.png"
	}
	
	SendWebhook(
		"🚨 Emergency Transport",
		"**" .. info.charName .. "** was emergency transported to hospital due to timeout.",
		15105570, -- Orange/Red
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)

local function CheckVersion()
	PerformHttpRequest('https://raw.githubusercontent.com/GLDNRMZ/'..GetCurrentResourceName()..'/main/version.txt', function(err, text, headers)
		local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
		if not text then 
			print('^1[GLDNRMZ] Unable to check version for '..GetCurrentResourceName()..'^0')
			return 
		end
		local result = text:gsub("\r", ""):gsub("\n", "")
		if result ~= currentVersion then
			print('^1[GLDNRMZ] '..GetCurrentResourceName()..' is out of date! Latest: '..result..' | Current: '..currentVersion..'^0')
		else
			print('^2[GLDNRMZ] '..GetCurrentResourceName()..' is up to date! ('..currentVersion..')^0')
		end
	end)
end

Citizen.CreateThread(function()
	CheckVersion()
end)
