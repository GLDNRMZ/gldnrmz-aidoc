local Bridge = exports['community_bridge']:Bridge()

local Active = false
local Revived = false
local calledHelp = false
local veh = nil
local ped1 = nil
local ped2 = nil
local ANIM_DICT = "mini@cpr@char_a@cpr_str"
local REVIVE_TIME = Config.ReviveTime * 1000
local PRICE = Config.Price

local lastDoctorTime = 0
local sleep = 200

local function DoRevive()
    TriggerServerEvent('aidoc:server:revive')
    return true
end

TriggerEvent('chat:addSuggestion', '/help', 'Call a Local Paramedic')
RegisterCommand("help", function(source, args, raw)
    if not Bridge.Framework.GetIsPlayerDead() then
        Bridge.Notify.SendNotify("This can only be used when dead", "error")
        return
    end

    if Config.JailCheck.enabled then
        local isJailed = false
        if Bridge.Framework.GetPlayerMetaData then
            local ok, value = pcall(Bridge.Framework.GetPlayerMetaData, Config.JailCheck.key)
            isJailed = ok and value or false
        end
        if isJailed then
            Bridge.Notify.SendNotify("This can't be used when in jail", "error")
            return
        end
    end

    local EMSOnline, hasEnoughMoney = Bridge.Callback.Trigger('aidoc:docOnline')
    if EMSOnline <= Config.Doctor --[[and hasEnoughMoney]] then
        if not calledHelp then
            calledHelp = true
            Revived = false
            lastDoctorTime = GetGameTimer()
            Bridge.Notify.SendNotify("Paramedic is on its Way", "primary", 60000)
            TriggerServerEvent('aidoc:webhook:helpCalled')
            SpawnVehicle(GetEntityCoords(PlayerPedId()))
        else
            Bridge.Notify.SendNotify("You've already called for help, please be patient", "error")
        end
    elseif EMSOnline > Config.Doctor then
        Bridge.Notify.SendNotify("There are too many medics on duty", "error")
    elseif not hasEnoughMoney then
        Bridge.Notify.SendNotify("Not Enough Money", "error")
    end
end)

function SpawnVehicle(x, y, z)
    spam = false
    local vehhash = GetHashKey(Config.Vehicle)

    RequestModel(vehhash)
    RequestModel('s_m_m_paramedic_01')
    while not HasModelLoaded(vehhash) or not HasModelLoaded('s_m_m_paramedic_01') do
        Wait(1)
    end

    local spawnRadius = 60
    local loc = GetEntityCoords(PlayerPedId())
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(loc.x + math.random(-spawnRadius, spawnRadius), loc.y + math.random(-spawnRadius, spawnRadius), loc.z, 0, 3, 0)

    if DoesEntityExist(vehhash) then
        return
    end

    local docVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)
    SetVehicleOnGroundProperly(docVeh)
    SetVehicleNumberPlateText(docVeh, "QUICKFIX")
    SetEntityAsMissionEntity(docVeh, true, true)
    SetVehicleEngineOn(docVeh, true, true, false)
    SetVehicleSiren(docVeh, true)

    local docPed = CreatePedInsideVehicle(docVeh, 26, GetHashKey('s_m_m_paramedic_01'), -1, true, false)
	local passengerPed = CreatePedInsideVehicle(docVeh, 26, GetHashKey('s_m_m_paramedic_01'), 0, true, false)
    docBlip = AddBlipForEntity(docVeh)
    SetBlipFlashes(docBlip, true)
    SetBlipColour(docBlip, 5)

    SetEntityInvincible(docPed, true)
    SetEntityInvincible(passengerPed, true)

    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
    Wait(2000)

    local docDriver = GetPedInVehicleSeat(docVeh, -1)
    TaskVehicleDriveToCoord(docDriver, docVeh, loc.x, loc.y, loc.z, 20.0, 0, GetEntityModel(docVeh), 524863, 2.0)

    veh = docVeh
    ped1 = docPed
	ped2 = passengerPed
    Active = true
    docEnRoute()
end

function docEnRoute()
    while not Revived do
        sleep = 200
        local playerPed = GetPlayerPed(-1)
        local loc = GetEntityCoords(playerPed)
        local lc = GetEntityCoords(veh)
        local ld = GetEntityCoords(ped1)
        local dist = #(loc - lc)
        local dist1 = #(loc - ld)
        local time = GetGameTimer()
        local timer = (time - lastDoctorTime)/1000
        if Config.Debug then print('Doc En Route - Dist: '..dist, 'Dist1: '..dist1, 'Time: '..time, 'lastDoctorTime: '..lastDoctorTime, 'Timer: '..timer..' seconds') end
        
        -- Check for emergency timeout
        if timer >= Config.EmergencyTimeout then
            DoScreenFadeOut(2000)
            -- Teleport to hospital using vector4 coordinates
            local coords = Config.HospitalCoords[1]
            SetEntityCoords(playerPed, coords.x, coords.y, coords.z, true, false, false, false)
            SetEntityHeading(playerPed, coords.w)
            Wait(2000)
            
            -- Clean up entities
            DeleteEntity(veh)
            DeleteEntity(ped1)
            DeleteEntity(ped2)
            
            -- First revive the player
            DoRevive()
            TriggerServerEvent('lb:charge')
            StopScreenEffect('DeathFailOut')
            Wait(1000) -- Give time for revive to process
            
            -- Now play wake up animation
            local playerPed = PlayerPedId()
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                Wait(10)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", 1.0)
            Wait(3000)
            ResetPedMovementClipset(playerPed, 1.0)
            
            Bridge.Notify.SendNotify("Emergency services transported you to the hospital", "primary")
            Bridge.Notify.SendNotify("Your treatment is done, you were charged: $"..Config.Price, "success")
            TriggerServerEvent('aidoc:webhook:emergencyTransport')
            
            calledHelp = false
            Revived = true
            DoScreenFadeIn(3000)
            break
        end
        
        if dist <= 10 then
            SetVehicleSiren(docVeh, false)
            if IsPedInAnyVehicle(playerPed, false) then
                local veh = GetVehiclePedIsIn(playerPed, false)
                TaskLeaveVehicle(playerPed, veh, 16)
            elseif Active then
                TaskGoToCoordAnyMeans(ped1, loc.x, loc.y, loc.z, 3.0, 0, 0, 786603, 0xbf800000)
            end
            if dist1 <= 1.5 then
                Active = false
                DoctorNPC()
                break
            end
        elseif lastDoctorTime > 0 and timer >= Config.TPTime then
            sleep = 3000
            SetVehicleSiren(docVeh, false)
            ClearPedTasksImmediately(ped1)
            if Config.Debug then print('TP to AI Doc Triggered') end
            if DoesEntityExist(ped1) then
                DoScreenFadeOut(500)
                SetEntityCoords(playerPed, ld.x + 5.0, ld.y + 5.0, ld.z, 0, 0, 0, 1)
                Wait(2500)
                DoScreenFadeIn(1500)
                lastDoctorTime = 0
            end
        end
        Wait(sleep)
    end
end

function DoctorNPC()
    if Config.Debug then print('DoctorNPC Triggered') end
	RequestAnimDict(ANIM_DICT)
	while not HasAnimDictLoaded(ANIM_DICT) do
		Wait(1000)
	end

	TaskPlayAnim(ped1, ANIM_DICT, "cpr_pumpchest", 1.0, 1.0, -1, 9, 1.0, 0, 0, 0)

	PlayAmbientSpeech1(ped1, "GENERIC_CURSE_HIGH", "SPEECH_PARAMS_FORCE", 3)
	Wait(2000)
	PlayAmbientSpeech1(ped2, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE", 3)

    local success = Bridge.ProgressBar.Open({
        duration = REVIVE_TIME,
        label = "HANG IN THERE BUDDY!!",
        useWhileDead = true,
        canCancel = false,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = true
        }
    })

    if success then
        ClearPedTasks(ped1)
        Wait(500)
        
        -- First revive the player
        DoRevive()
        TriggerServerEvent('lb:charge')
        StopScreenEffect('DeathFailOut')
        Wait(1000) -- Give time for revive to process
        
        -- Now play wake up animation
        local playerPed = PlayerPedId()
        RequestAnimSet("move_m@drunk@verydrunk")
        while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
            Wait(10)
        end
        SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", 1.0)
        Wait(3000)
        ResetPedMovementClipset(playerPed, 1.0)
        
        Bridge.Notify.SendNotify("Your treatment is done, you were charged: $"..Config.Price, "success")
        TriggerServerEvent('aidoc:webhook:playerHealed')
        calledHelp = false
        Revived = true

        --RemovePedElegantly(ped1)
        TaskEnterVehicle(ped1, veh, 0, 2, 3.0, 1, 0)
        TaskVehicleDriveWander(ped1, veh, 25.0, 524295)
        Wait(20000)
        DeleteEntity(veh)
        DeleteEntity(ped1)
        DeleteEntity(ped2)
    end
end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		DeleteEntity(veh)
		DeleteEntity(ped1)
		DeleteEntity(ped2)
    end
end)
