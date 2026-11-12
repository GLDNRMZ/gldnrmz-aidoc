Webhook = {}

local cfg = ServerConfig.Webhook

---Discord markdown would let player-controlled text (names) break formatting.
local function escape(text)
    return (tostring(text or ''):gsub('([\\`*_~|>])', '\\%1'))
end
Webhook.Escape = escape

local function isEnabled()
    return cfg.enabled and type(cfg.url) == 'string' and cfg.url:find('^https://') ~= nil
end

---@param title string
---@param description string
---@param color number
---@param fields table[]?
function Webhook.Send(title, description, color, fields)
    if not isEnabled() then return end

    local payload = {
        username = cfg.botName,
        avatar_url = cfg.avatar,
        embeds = { {
            title = title,
            description = description,
            color = color,
            fields = fields or {},
            thumbnail = cfg.thumbnail and { url = cfg.thumbnail } or nil,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            footer = cfg.footer and { text = cfg.footer } or nil,
        } },
    }

    PerformHttpRequest(cfg.url, function(status)
        if status < 200 or status >= 300 then
            print(('^3[gldnrmz-aidoc] Webhook request failed (HTTP %s)^0'):format(status))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

---Standard "who" field for a player.
---@param label string
---@param info table from GetPlayerInfo
function Webhook.PlayerField(label, info)
    return {
        name = label,
        value = ('**Name:** %s\n**Character:** %s\n**Identifier:** `%s`\n**Server ID:** `%d`\n**Job:** %s')
            :format(escape(info.playerName), escape(info.charName), info.identifier, info.source, escape(info.job)),
        inline = true,
    }
end
