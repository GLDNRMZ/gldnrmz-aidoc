fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gldnrmz-aidoc'
description 'AI paramedic that revives downed players when EMS is unavailable'
version '2.1.0'
authors 'GLDNRMZ#8700 / HHFW / Sanriku / amrclake'

shared_scripts {
    'config.lua',
}

server_scripts {
    'server/config.lua', -- server-only: never sent to clients (webhook URL lives here)
    'server/webhook.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'community_bridge',
}
