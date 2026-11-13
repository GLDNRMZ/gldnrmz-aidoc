local Bridge = exports['community_bridge']:Bridge()

---Downed on any framework: community_bridge metadata, the isDead / dead state bags
---(esx_ambulancejob, wasabi_ambulance), ESX's own dead flag, or a dead ped.
local function isDowned()
    local ok, dead = pcall(Bridge.Framework.GetIsPlayerDead)
    if ok and dead then return true end
    local bag = LocalPlayer.state
    if bag.isDead or bag.dead then return true end
    if GetResourceState('es_extended') == 'started' then
        local okEsx, esxDead = pcall(function() return exports.es_extended:getSharedObject().PlayerData.dead end)
        if okEsx and esxDead then return true end
    end
    return IsEntityDead(PlayerPedId())
end
local L = Config.Locale

local CPR_DICT, CPR_ANIM = 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest'
local WAKE_CLIPSET = 'move_m@drunk@verydrunk'
local MEDIC_REACH = 2.0        -- metres from player to start CPR
local ARRIVE_RANGE = 15.0      -- metres from player where the medic gets out and walks
local WARP_GRACE = 15          -- seconds after the ambulance is moved before the medic is placed next to the player

local state = {
    id = 0,           -- increases per call so stale threads stop themselves
    active = false,
    startedAt = 0,
    vehicle = nil,
    medic = nil,
    partner = nil,
    blip = nil,
}

local function debugPrint(...)
    if Config.Debug then print('[gldnrmz-aidoc]', ...) end
end

local function notify(message, nType, duration)
    Bridge.Notify.SendNotify(message, nType, duration)
end

local function isCurrent(id)
    return state.active and state.id == id
end

local function elapsedSeconds()
    return (GetGameTimer() - state.startedAt) / 1000
end

--------------------------------------------------------------------------------
-- Asset loading (all with timeouts so a bad model name can't hang the script)
--------------------------------------------------------------------------------

local function waitFor(check, timeout)
    local deadline = GetGameTimer() + (timeout or 5000)
    while not check() do
        if GetGameTimer() > deadline then return false end
        Wait(0)
    end
    return true
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        print(('^1[gldnrmz-aidoc] Invalid model: %s^0'):format(model))
        return nil
    end
    RequestModel(hash)
    return waitFor(function() return HasModelLoaded(hash) end, 10000) and hash or nil
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    return waitFor(function() return HasAnimDictLoaded(dict) end)
end

local function loadClipSet(clipSet)
    RequestAnimSet(clipSet)
    return waitFor(function() return HasAnimSetLoaded(clipSet) end)
end

--------------------------------------------------------------------------------
-- Entities
--------------------------------------------------------------------------------

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---Removes the crew. With `immediate` false, the medic drives away first.
local function dismissCrew(immediate)
    local vehicle, medic, partner, blip = state.vehicle, state.medic, state.partner, state.blip
    state.vehicle, state.medic, state.partner, state.blip = nil, nil, nil, nil

    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end

    if immediate or not (vehicle and medic and DoesEntityExist(vehicle) and DoesEntityExist(medic)) then
        deleteEntity(medic)
        deleteEntity(partner)
        deleteEntity(vehicle)
        return
    end

    CreateThread(function()
        ClearPedTasks(medic)
        TaskEnterVehicle(medic, vehicle, 10000, -1, 2.0, 1, 0) -- -1 = driver seat
        local seated = waitFor(function()
            return not DoesEntityExist(medic) or GetPedInVehicleSeat(vehicle, -1) == medic
        end, 12000)

        if DoesEntityExist(medic) and DoesEntityExist(vehicle) then
            -- Blocked path or door: put him in the driver's seat directly.
            if not seated then
                SetPedIntoVehicle(medic, vehicle, -1)
            end
            SetVehicleSiren(vehicle, false)
            TaskVehicleDriveWander(medic, vehicle, 20.0, Config.Vehicle.drivingStyle)
        end

        Wait(20000)
        deleteEntity(medic)
        deleteEntity(partner)
        deleteEntity(vehicle)
    end)
end

local function setupMedic(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeDraggedOut(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
end

---Finds a road node roughly `spawnDistance` away from the player.
local function findSpawnPoint(origin)
    local distance = Config.Vehicle.spawnDistance
    for _ = 1, 10 do
        local angle = math.random() * 2.0 * math.pi
        local found, pos, heading = GetClosestVehicleNodeWithHeading(
            origin.x + math.cos(angle) * distance,
            origin.y + math.sin(angle) * distance,
            origin.z, 1, 3.0, 0)
        if found and #(pos - origin) > ARRIVE_RANGE then
            return pos, heading
        end
    end
    local found, pos, heading = GetClosestVehicleNodeWithHeading(origin.x, origin.y, origin.z, 1, 3.0, 0)
    if found then return pos, heading end
end

local function driveTo(coords)
    if not (state.medic and state.vehicle) then return end
    TaskVehicleDriveToCoordLongrange(state.medic, state.vehicle, coords.x, coords.y, coords.z,
        Config.Vehicle.driveSpeed, Config.Vehicle.drivingStyle, 5.0)
end

local function spawnCrew(origin)
    local vehicleHash = loadModel(Config.Vehicle.model)
    local pedHash = loadModel(Config.MedicModel)
    if not vehicleHash or not pedHash then return false end

    local pos, heading = findSpawnPoint(origin)
    if not pos then return false end

    local vehicle = CreateVehicle(vehicleHash, pos.x, pos.y, pos.z, heading, true, false)
    if not waitFor(function() return DoesEntityExist(vehicle) end) then return false end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, Config.Vehicle.plate)
    SetVehicleDoorsLockedForAllPlayers(vehicle, true) -- players can't get in, the NPC crew still can
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleSiren(vehicle, true)

    local medic = CreatePedInsideVehicle(vehicle, 26, pedHash, -1, true, false)
    local partner = CreatePedInsideVehicle(vehicle, 26, pedHash, 0, true, false)
    setupMedic(medic)
    setupMedic(partner)

    SetModelAsNoLongerNeeded(vehicleHash)
    SetModelAsNoLongerNeeded(pedHash)

    state.vehicle, state.medic, state.partner = vehicle, medic, partner

    if Config.Blip.enabled then
        local blip = AddBlipForEntity(vehicle)
        SetBlipColour(blip, Config.Blip.colour)
        SetBlipFlashes(blip, Config.Blip.flash)
        state.blip = blip
    end

    driveTo(origin)
    return true
end

---Moves the ambulance to the nearest road next to the player (it's stuck or lost).
local function moveCrewToPlayer(playerPos)
    if not (state.vehicle and DoesEntityExist(state.vehicle)) then return end
    local found, node, heading = GetClosestVehicleNodeWithHeading(playerPos.x, playerPos.y, playerPos.z, 1, 3.0, 0)
    if not found then return end
    debugPrint('moving stuck ambulance to player')
    SetEntityCoords(state.vehicle, node.x, node.y, node.z, false, false, false, false)
    SetEntityHeading(state.vehicle, heading)
    SetVehicleOnGroundProperly(state.vehicle)
    driveTo(playerPos)
end

---Last resort: put the medic on foot right next to the player.
local function warpMedicToPlayer(playerPos)
    if not (state.medic and DoesEntityExist(state.medic)) then return end
    debugPrint('warping medic next to player')
    ClearPedTasksImmediately(state.medic)
    SetEntityCoords(state.medic, playerPos.x + 1.0, playerPos.y + 1.0, playerPos.z, false, false, false, false)
end

local function getPedSeat(ped, vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end
end

---The medic walks to the player's vehicle and drags them out of their seat.
---If that fails (blocked door, another script holding the player), the player
---is placed outside instead.
local function pullPlayerOut(id)
    local medic = state.medic
    local playerPed = PlayerPedId()
    local car = GetVehiclePedIsIn(playerPed, false)
    if car == 0 or not (medic and DoesEntityExist(medic)) then return end

    local seat = getPedSeat(playerPed, car) or -1
    debugPrint('pulling player out of vehicle, seat', seat)

    -- Out of the ambulance first.
    if IsPedInAnyVehicle(medic, false) then
        TaskLeaveVehicle(medic, GetVehiclePedIsIn(medic, false), 0)
        waitFor(function() return not isCurrent(id) or not IsPedInAnyVehicle(medic, false) end, 5000)
    end
    if not isCurrent(id) then return end

    -- Seatbelt scripts often disable being dragged out.
    SetPedCanBeDraggedOut(playerPed, true)

    -- Flag 8 = jack: the medic runs to the door and drags whoever is in that seat out.
    TaskEnterVehicle(medic, car, 15000, seat, 2.0, 8, 0)
    waitFor(function()
        return not isCurrent(id) or not DoesEntityExist(medic) or not IsPedInAnyVehicle(PlayerPedId(), false)
    end, 15000)
    if not isCurrent(id) or not DoesEntityExist(medic) then return end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        debugPrint('drag-out failed, placing player outside')
        TaskLeaveVehicle(PlayerPedId(), car, 16)
    end

    -- Stop the medic climbing into the seat he just emptied.
    Wait(500)
    if IsPedInAnyVehicle(medic, false) then
        TaskLeaveVehicle(medic, car, 0)
        if not waitFor(function() return not IsPedInAnyVehicle(medic, false) end, 5000) then
            TaskLeaveVehicle(medic, car, 16)
        end
    else
        ClearPedTasks(medic)
    end
end

--------------------------------------------------------------------------------
-- Outcomes
--------------------------------------------------------------------------------

local function playWakeUp()
    StopScreenEffect('DeathFailOut')
    Wait(1000) -- let the ambulance script finish its revive first
    if not loadClipSet(WAKE_CLIPSET) then return end
    SetPedMovementClipset(PlayerPedId(), WAKE_CLIPSET, 1.0)
    SetTimeout(3000, function()
        ResetPedMovementClipset(PlayerPedId(), 1.0)
        RemoveClipSet(WAKE_CLIPSET)
    end)
end

local function cancelService(reason, message)
    if not state.active then return end
    state.active = false
    TriggerServerEvent('gldnrmz-aidoc:server:cancel', reason)
    dismissCrew(false)
    if message then notify(message, 'error') end
    debugPrint('cancelled:', reason)
end

local function nearestHospital(pos)
    local bestIndex, bestDist = 1, math.huge
    for i, hospital in ipairs(Config.Hospitals) do
        local dist = #(pos - hospital.coords.xyz)
        if dist < bestDist then bestIndex, bestDist = i, dist end
    end
    return bestIndex, Config.Hospitals[bestIndex]
end

local function emergencyTransport()
    state.active = false
    local ped = PlayerPedId()
    local index, hospital = nearestHospital(GetEntityCoords(ped))

    DoScreenFadeOut(1000)
    waitFor(IsScreenFadedOut, 3000)
    dismissCrew(true)

    local success, price = Bridge.Callback.Trigger('gldnrmz-aidoc:server:complete', 'transported', index)
    if success then
        Wait(1000) -- revive first, then move the (now alive) player
        local c = hospital.coords
        ped = PlayerPedId()
        SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
        SetEntityHeading(ped, c.w)
    end

    DoScreenFadeIn(2000)

    if success then
        notify(L.transported:format(hospital.label), 'primary')
        notify(L.treated:format(price or Config.Price), 'success')
        playWakeUp()
    else
        notify(L.cancelled, 'error')
    end
end

local function treat()
    state.active = false
    local medic, partner = state.medic, state.partner
    local playerPed = PlayerPedId()

    ClearPedTasks(medic)
    TaskTurnPedToFaceEntity(medic, playerPed, 1000)
    Wait(1000)

    local hasAnim = loadAnimDict(CPR_DICT)
    if hasAnim then
        TaskPlayAnim(medic, CPR_DICT, CPR_ANIM, 1.0, 1.0, -1, 9, 1.0, false, false, false)
    end
    PlayAmbientSpeech1(medic, 'GENERIC_CURSE_HIGH', 'SPEECH_PARAMS_FORCE')
    if partner and DoesEntityExist(partner) then
        PlayAmbientSpeech1(partner, 'GENERIC_INSULT_HIGH', 'SPEECH_PARAMS_FORCE')
    end

    local finished = Bridge.ProgressBar.Open({
        duration = Config.ReviveTime * 1000,
        label = L.progress_label,
        useWhileDead = true,
        canCancel = false,
        disable = { move = false, car = false, mouse = false, combat = true },
    })

    if DoesEntityExist(medic) then ClearPedTasks(medic) end
    if hasAnim then RemoveAnimDict(CPR_DICT) end

    if not finished then
        state.active = true -- let cancelService run its cleanup
        cancelService('progress_interrupted', L.cancelled)
        return
    end

    local success, price = Bridge.Callback.Trigger('gldnrmz-aidoc:server:complete', 'treated')
    dismissCrew(false)

    if success then
        notify(L.treated:format(price or Config.Price), 'success')
        playWakeUp()
    else
        notify(L.cancelled, 'error')
    end
end

--------------------------------------------------------------------------------
-- Main flow
--------------------------------------------------------------------------------

local function runService(id)
    local origin = GetEntityCoords(PlayerPedId())
    if not spawnCrew(origin) then
        dismissCrew(true)
        cancelService('spawn_failed', L.spawn_failed)
        return
    end

    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)

    local arrived, movedAt, warped = false, nil, false
    local lastWalkTask = 0
    local pullAttempted = false

    while isCurrent(id) do
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        local elapsed = elapsedSeconds()

        if not isDowned() then
            cancelService('revived_elsewhere')
            return
        end

        if elapsed >= Config.EmergencyTimeout then
            emergencyTransport()
            return
        end

        local medic, vehicle = state.medic, state.vehicle
        if medic and DoesEntityExist(medic) and vehicle and DoesEntityExist(vehicle) then
            local medicDist = #(playerPos - GetEntityCoords(medic))
            local vehicleDist = #(playerPos - GetEntityCoords(vehicle))

            if Config.Debug then
                debugPrint(('elapsed %.0fs | vehicle %.1fm | medic %.1fm'):format(elapsed, vehicleDist, medicDist))
            end

            local playerInVehicle = IsPedInAnyVehicle(playerPed, false)

            if medicDist <= MEDIC_REACH and not playerInVehicle and not IsPedInAnyVehicle(medic, false) then
                treat()
                return
            end

            if not arrived and (vehicleDist <= ARRIVE_RANGE or warped) then
                arrived = true
                SetVehicleSiren(vehicle, false)
            end

            if arrived and playerInVehicle and not pullAttempted then
                pullAttempted = true
                pullPlayerOut(id)
                lastWalkTask = 0
            -- Re-issue the walk task every few seconds instead of every tick,
            -- so the task isn't constantly restarted.
            elseif arrived and not playerInVehicle and GetGameTimer() - lastWalkTask > 3000 then
                lastWalkTask = GetGameTimer()
                TaskGoToCoordAnyMeans(medic, playerPos.x, playerPos.y, playerPos.z, 2.0, 0, false, 786603, 0xbf800000)
            end

            if not arrived and not movedAt and elapsed >= Config.TeleportTime then
                movedAt = elapsed
                moveCrewToPlayer(playerPos)
            elseif movedAt and not warped and elapsed >= movedAt + WARP_GRACE then
                warped = true
                warpMedicToPlayer(playerPos)
            end
        end

        Wait(arrived and 100 or 250)
    end
end

---Starts an AI doctor call for the local player.
---@return boolean started
local function requestService()
    if state.active then
        notify(L.already_called, 'error')
        return false
    end

    if not isDowned() then
        notify(L.not_dead, 'error')
        return false
    end

    local ok, reason = Bridge.Callback.Trigger('gldnrmz-aidoc:server:request')
    if not ok then
        notify(reason or L.cancelled, 'error')
        return false
    end

    state.id = state.id + 1
    state.active = true
    state.startedAt = GetGameTimer()
    notify(L.on_the_way, 'primary', 10000)

    local id = state.id
    CreateThread(function() runService(id) end)
    return true
end

--------------------------------------------------------------------------------
-- Command, events, exports
--------------------------------------------------------------------------------

if Config.Command and Config.Command.name then
    RegisterCommand(Config.Command.name, function() requestService() end, false)
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command.name, Config.Command.description)
end

-- Sent by the server export CancelService (e.g. real EMS took over).
RegisterNetEvent('gldnrmz-aidoc:client:cancel', function()
    if not state.active then return end
    state.active = false
    dismissCrew(false)
    notify(L.cancelled, 'primary')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    state.active = false
    dismissCrew(true)
end)

exports('RequestService', requestService)
exports('IsServiceActive', function() return state.active end)
exports('CancelService', function()
    if not state.active then return false end
    cancelService('player_cancelled', L.cancelled)
    return true
end)
