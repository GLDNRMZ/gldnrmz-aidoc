local QBCore = exports['qb-core']:GetCoreObject()

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

QBCore.Functions.CreateCallback('lb:docOnline', function(source, cb)
	local src = source
	local Ply = QBCore.Functions.GetPlayer(src)
	local xPlayers = QBCore.Functions.GetPlayers()
	local doctor = 0
	local canpay = false
	if Ply.PlayerData.money["cash"] >= Config.Price then
		canpay = true
	else
		if Ply.PlayerData.money["bank"] >= Config.Price then
			canpay = true
		end
	end

	for i=1, #xPlayers, 1 do
        local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
        if xPlayer.PlayerData.job.name == 'ambulance' and xPlayer.PlayerData.job.onduty then
            doctor = doctor + 1
        end
    end

	cb(doctor, canpay)
end)

RegisterServerEvent('lb:charge')
AddEventHandler('lb:charge', function()
	local src = source
	local xPlayer = QBCore.Functions.GetPlayer(src)
	if xPlayer.PlayerData.money["cash"] >= Config.Price then
		xPlayer.Functions.RemoveMoney("cash", Config.Price, GetCurrentResourceName()..' - AI Doc Fees')
	else
		xPlayer.Functions.RemoveMoney("bank", Config.Price, GetCurrentResourceName()..' - AI Doc Fees')
	end
	exports['Renewed-Banking']:addAccountMoney('ambulance', Config.Price, 'AI Doctor Service')
end)

-- Webhook Events
RegisterServerEvent('aidoc:webhook:helpCalled')
AddEventHandler('aidoc:webhook:helpCalled', function()
	local src = source
	local xPlayer = QBCore.Functions.GetPlayer(src)
	local playerName = xPlayer.PlayerData.name
	local charName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
	local citizenid = xPlayer.PlayerData.citizenid
	local job = xPlayer.PlayerData.job.label or "Unemployed"
	local cash = xPlayer.PlayerData.money.cash or 0
	local bank = xPlayer.PlayerData.money.bank or 0
	
	local fields = {
		{
			["name"] = "👤 Player Information",
			["value"] = "```\n" .. playerName .. "```\n**Character:** " .. charName .. "\n**Citizen ID:** `" .. citizenid .. "`\n**Job:** " .. job,
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
		"**" .. charName .. "** requested AI Doctor services.",
		15158332, -- Red
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)

RegisterServerEvent('aidoc:webhook:playerHealed')
AddEventHandler('aidoc:webhook:playerHealed', function()
	local src = source
	local xPlayer = QBCore.Functions.GetPlayer(src)
	local playerName = xPlayer.PlayerData.name
	local charName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
	local citizenid = xPlayer.PlayerData.citizenid
	local job = xPlayer.PlayerData.job.label or "Unemployed"
	
	local fields = {
		{
			["name"] = "👤 Patient Information",
			["value"] = "```\n" .. playerName .. "```\n**Character:** " .. charName .. "\n**Citizen ID:** `" .. citizenid .. "`\n**Job:** " .. job,
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
		"**" .. charName .. "** was successfully treated by AI Doctor.",
		3066993, -- Green
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)

RegisterServerEvent('aidoc:webhook:emergencyTransport')
AddEventHandler('aidoc:webhook:emergencyTransport', function()
	local src = source
	local xPlayer = QBCore.Functions.GetPlayer(src)
	local playerName = xPlayer.PlayerData.name
	local charName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
	local citizenid = xPlayer.PlayerData.citizenid
	local job = xPlayer.PlayerData.job.label or "Unemployed"
	
	local fields = {
		{
			["name"] = "🆘 Critical Patient",
			["value"] = "```\n" .. playerName .. "```\n**Character:** " .. charName .. "\n**Citizen ID:** `" .. citizenid .. "`\n**Job:** " .. job,
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
		"**" .. charName .. "** was emergency transported to hospital due to timeout.",
		15105570, -- Orange/Red
		fields,
		"https://i.imgur.com/oc7sWCV.png",
		author
	)
end)
