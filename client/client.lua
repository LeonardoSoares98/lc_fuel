-- Shared variables
Utils = Utils or exports['lc_utils']:GetUtils()
cachedTranslations = {}
mainUiOpen = false

fuelNozzle = 0
fuelRope = 0
currentPump = 0
JERRY_CAN_HASH = 883325847

-- Fuel chart variables
isFuelConsumptionChartOpen = false
isRecording = true

-- Local variables
local fuelDecor = "_FUEL_LEVEL"
local currentConsumption = 0.0
local fuelSynced = false
local closestVehicleToPump = 0
local isNuiVariablesLoaded = false

DecorRegister(fuelDecor, 1)
-- Check if it actually registered
if DecorIsRegisteredAsType(fuelDecor, 1) then
    print("[Fuel Script] SUCCESS: fuelDecor was registered successfully!")
else
    print("[Fuel Script] ERROR: fuelDecor registration failed!")
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Threads
-----------------------------------------------------------------------------------------------------------------------------------------

-- Thread to handle the fuel consumption
function createFuelConsumptionThread()
    CreateThread(function()
        local currentVehicle = nil
        local currentVehicleFuelType = "default" -- default while the callback loads
        DecorRegister(fuelDecor, 1)
        while true do
            Wait(1000)
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(vehicle, -1) == ped and not IsVehicleBlacklisted(vehicle) then
                    if currentVehicle == nil or currentVehicle ~= vehicle then
                        currentVehicle = vehicle
                        currentVehicleFuelType = getVehicleFuelTypeFromServer(vehicle)
                        fuelSynced = false
                    end
                    HandleFuelConsumption(vehicle, currentVehicleFuelType)
                end
            else
                if isFuelConsumptionChartOpen then
                    closeFuelConsumptionChartUI()
                end
                currentVehicleFuelType = "default"
                currentVehicle = nil
                fuelSynced = false
            end
        end
    end)
end

function HandleFuelConsumption(vehicle, fuelType)
    -- If no decorator exists, set a random fuel %
    if not DecorExistOn(vehicle, fuelDecor) then
        SetFuel(vehicle, math.random(200, 800) / 10)
    elseif not fuelSynced then
        -- Sync once
        SetFuel(vehicle, GetFuel(vehicle))
        fuelSynced = true
    end

    -- If engine is off, do nothing
    if not GetIsVehicleEngineRunning(vehicle) then
        return
    end

    -- Turns engine off if have no fuel
    local currentFuelLevel = GetVehicleFuelLevel(vehicle)
    if currentFuelLevel <= 0.0 then
        SetVehicleEngineOn(vehicle, false, true, false)
        return
    end

    -- Get the vehicle's actual tank size in liters
    local tankSize = getVehicleTankSize(vehicle)

    -- Base consumption from config and RPM
    currentConsumption = Config.FuelUsage[Utils.Math.round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.FuelConsumptionPerClass[GetVehicleClass(vehicle)] or 1.0) * (Config.FuelConsumptionPerFuelType[fuelType] or 1.0) / 10

    -- Scale consumption according to tank size.
    -- A smaller tank will lose percentage faster; a bigger tank slower.
    local scaledConsumption = currentConsumption * (100 / tankSize)

    -- Subtract from the current fuel % 
    local newFuelLevel = currentFuelLevel - scaledConsumption

    -- Write the new fuel % back
    SetFuel(vehicle, newFuelLevel)

    -- Store data for chart
    if Config.FuelConsumptionChart.enabled then
        storeDataForChart(vehicle, newFuelLevel, currentConsumption)
    end

    validateDieselFuelMismatch(vehicle, fuelType)
end

function validateDieselFuelMismatch(vehicle, fuelType)
    if (fuelType == "diesel" and not IsVehicleDiesel(vehicle)) or (fuelType ~= "diesel" and IsVehicleDiesel(vehicle)) then
        SetTimeout(5000, function()
            if IsVehicleDriveable(vehicle, false) then
                SetVehicleEngineHealth(vehicle, 0.0)
                SetVehicleUndriveable(vehicle, true)
                exports['lc_utils']:notify("error", Utils.translate("vehicle_wrong_fuel"))
            end
        end)
    end
end

function createDebugNozzleOffsetThread()
    CreateThread(function()
        while true do
            local vehicle = GetVehiclePlayerIsLookingAt()
            if not vehicle or not DoesEntityExist(vehicle) then
                Wait(2)
                goto continue -- Skip if no valid vehicle found
            end

            local hit, hitCoords = GetLookAtHitCoords()
            if hit and DoesEntityExist(vehicle) then
                local offset = GetNozzleOffset(vehicle, hitCoords)

                if offset then
                    local vehCoords = GetEntityCoords(vehicle)

                    -- Get vehicle's axis vectors
                    local _, rightVector, _ = GetEntityMatrix(vehicle)

                    -- Direction from vehicle to hit point
                    local directionToHit = hitCoords - vehCoords
                    directionToHit = directionToHit / #(directionToHit) -- normalize

                    -- Dot product with right vector
                    local side = rightVector.x * directionToHit.x + rightVector.y * directionToHit.y + rightVector.z * directionToHit.z

                    -- Adjust offset.right
                    if side > 0 then
                        -- hit is on the right side
                        offset.right = offset.right + 0.07
                    else
                        -- hit is on the left side
                        offset.right = offset.right - 0.07
                    end

                    -- Final world position of the nozzle point
                    local finalWorldPos = getWorldPosFromOffset(vehicle, offset)

                    -- Draw a small marker at the computed position
                    DrawMarker(28, finalWorldPos.x, finalWorldPos.y, finalWorldPos.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03, 0.03, 0.03, 255, 0, 0, 180, false, true, 2, nil, nil, false)

                    if IsControlJustPressed(0,38) then
                        local model = GetEntityModel(vehicle)
                        local modelName = GetDisplayNameFromVehicleModel(model):lower()
                        
                        local zRotation = side > 0 and 180 or 0

                        local clipboardText = string.format(
                            '["%s"] = { distance = 1.3, nozzleOffset = { forward = %.2f, right = %.2f, up = %.2f }, nozzleRotation = { x = 0, y = 0, z = %d } },',
                            modelName,
                            offset.forward, offset.right, offset.up,
                            zRotation
                        )

                        SendNUIMessage({
                            type = "copyToClipboard",
                            text = clipboardText
                        })

                        exports['lc_utils']:notify("success", "Copied to clipboard: " .. clipboardText)
                        exports['lc_utils']:notify("warning", "Make sure the vehicle spawn name is correct. You may need to manually fine-tune the offset and rotation.")
                    end
                end
            end
            Wait(2)
            ::continue::
        end
    end)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------------------------------------------------------------------

function clientOpenUI(pump, pumpModel, isElectricPump)
    currentPump = pump
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    closestVehicleToPump = GetClosestVehicle(playerCoords)
    local isElectricVehicle = IsVehicleElectric(closestVehicleToPump)
    if not (isElectricVehicle and isElectricPump) and not (not isElectricVehicle and  not isElectricPump) then
        -- Reset the near vehicle to 0 when it does not match the pump type (only allows electric vehicle in electric chargers and gas vehicles in gas pumps)
        closestVehicleToPump = 0
    end

    pumpLocation = nil

    if closestVehicleToPump and #(playerCoords - GetEntityCoords(closestVehicleToPump)) < 5 then
        -- Load the nearest vehicle fuel and plate (fuel type)
        local vehicleFuel = GetFuel(closestVehicleToPump)
        local vehiclePlate = GetVehicleNumberPlateText(closestVehicleToPump)
        local vehicleTankSize = getVehicleTankSize(closestVehicleToPump)
        local vehicleDisplayFuelAmount = getVehicleDisplayFuelAmount(vehicleFuel, vehicleTankSize)
        TriggerServerEvent("lc_fuel:serverOpenUI", isElectricPump, pumpModel, vehicleDisplayFuelAmount, vehicleTankSize, vehiclePlate)
    else
        -- Allow the user to open the UI even without vehicles nearby
        TriggerServerEvent("lc_fuel:serverOpenUI", isElectricPump, pumpModel)
    end
end

function loadNuiVariables()
    if isNuiVariablesLoaded then
        return
    end

    -- Load NUI variables
    SendNUIMessage({
        utils = { config = Utils.Config, lang = Utils.Lang },
        resourceName = GetCurrentResourceName()
    })

    local maxIterations = 100 -- Maximum number of iterations (100 * 100ms = 10 seconds)
    local iterations = 0

    while not isNuiVariablesLoaded do
        Wait(100)
        iterations = iterations + 1

        if iterations >= maxIterations then
            print("Error: Timeout while loading NUI variables after " .. iterations .. " attempts.")
            return
        end
    end
end


RegisterNetEvent('lc_fuel:clientOpenUI')
AddEventHandler('lc_fuel:clientOpenUI', function(data)
    loadNuiVariables()
    data.currentFuelType = dealWithDefaultFuelType(closestVehicleToPump, data.currentFuelType)
    SendNUIMessage({
        openMainUI = true,
        data = data
    })
    mainUiOpen = true
    TriggerScreenblurFadeIn(1000)
    FreezeEntityPosition(PlayerPedId(), true)
    SetNuiFocus(true,true)
end)

RegisterNUICallback('post', function(body, cb)
    if cooldown == nil then
        cooldown = true

        if body.event == "close" then
            closeUI()
        elseif body.event == "closeFuelConsumptionChartUI" then
            closeFuelConsumptionChartUI()
        elseif body.event == "removeFocusFuelConsumptionChartUI" then
            SetNuiFocus(false,false)
        elseif body.event == "startRecordingGraph" then
            isRecording = true
        elseif body.event == "stopRecordingGraph" then
            isRecording = false
        elseif body.event == "notify" then
            exports['lc_utils']:notify(body.data.type,body.data.msg)
        elseif body.event == "changeVehicleFuelType" then
            changeVehicleFuelType(closestVehicleToPump, body.data.selectedFuelType)
        else
            TriggerServerEvent('lc_fuel:'..body.event,body.data)
        end
        cb(200)

        SetTimeout(5,function()
            cooldown = nil
        end)
    end
end)

RegisterNUICallback('setNuiVariablesLoaded', function(body, cb)
    isNuiVariablesLoaded = true
    cb(200)
end)

function closeUI()
    mainUiOpen = false
    FreezeEntityPosition(PlayerPedId(), false)
    TriggerScreenblurFadeOut(1000)
    SetNuiFocus(false,false)
    SendNUIMessage({ hideMainUI = true })
end

RegisterNetEvent('lc_fuel:closeUI')
AddEventHandler('lc_fuel:closeUI', function()
    closeUI()
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- Exports
-----------------------------------------------------------------------------------------------------------------------------------------

function GetFuel(vehicle)
    if not DoesEntityExist(vehicle) then
        warn(("[GetFuel] Vehicle entity does not exist. Received: %s. This is usually caused by a misconfiguration in the export."):format(tostring(vehicle)))
        return 0
    end
    return DecorGetFloat(vehicle, fuelDecor)
end
exports('GetFuel', GetFuel)

function SetFuel(vehicle, fuel)
    if not DoesEntityExist(vehicle) then
        warn(("[SetFuel] Vehicle entity does not exist. Received: %s. This is usually caused by a misconfiguration in the export."):format(tostring(vehicle)))
        return
    end

    if type(fuel) ~= "number" then
        warn(("[SetFuel] Invalid fuel value received: %s. Fuel must be a number between 0 and 100."):format(tostring(fuel)))
        return
    end

    -- Normalize the fuel values if received negative values or higher than 100
    fuel = math.max(0.0, math.min(fuel, 100.0))

    SetVehicleFuelLevel(vehicle, fuel + 0.0)
    DecorSetFloat(vehicle, fuelDecor, GetVehicleFuelLevel(vehicle))
end
exports('SetFuel', SetFuel)

-- Just another way to call the exports in case someone does it like this...
function getFuel(vehicle)
    return GetFuel(vehicle)
end
exports('getFuel', getFuel)

function setFuel(vehicle, fuel)
    SetFuel(vehicle, fuel)
end
exports('setFuel', setFuel)

-- Alias LegacyFuel's exports to point to our lc_fuel functions:
AddEventHandler('__cfx_export_LegacyFuel_SetFuel', function(setCB)
    -- Redirect LegacyFuel:SetFuel to use lc_fuel's SetFuel function
    setCB(SetFuel)
end)

AddEventHandler('__cfx_export_LegacyFuel_GetFuel', function(setCB)
    -- Redirect LegacyFuel:GetFuel to use lc_fuel's GetFuel function
    setCB(GetFuel)
end)

function SetFuelType(vehicle, fuelType)
    if not DoesEntityExist(vehicle) then
        warn(("[SetFuelType] Vehicle entity does not exist. Received: %s. This is usually caused by a misconfiguration in the export."):format(tostring(vehicle)))
        return
    end
    if not fuelType or fuelType == "nil" or fuelType == "" then
        fuelType = dealWithDefaultFuelType(vehicle, "default")
    end
    TriggerServerEvent("lc_fuel:setVehicleFuelType", GetVehicleNumberPlateText(vehicle), fuelType)
end
exports('SetFuelType', SetFuelType)

function setFuelType(vehicle, fuelType)
    return SetFuelType(vehicle, fuelType)
end
exports('setFuelType', setFuelType)

-----------------------------------------------------------------------------------------------------------------------------------------
-- Utils
-----------------------------------------------------------------------------------------------------------------------------------------

function getVehicleFuelTypeFromServer(vehicle)
    local returnFuelType = nil

    Utils.Callback.TriggerServerCallback('lc_fuel:getVehicleFuelType', function(fuelType)
        returnFuelType = dealWithDefaultFuelType(vehicle, fuelType)
    end, GetVehicleNumberPlateText(vehicle))

    while returnFuelType == nil do
        Wait(10)
    end
    return returnFuelType
end

function dealWithDefaultFuelType(vehicle, fuelType)
    -- Define if the vehicle is diesel or gasoline for the ones that have never been refueled
    if fuelType == "default" then
        if IsVehicleDiesel(vehicle) then
            fuelType = "diesel"
        elseif IsVehicleElectric(vehicle) then
            fuelType = "electric"
        else
            fuelType = "regular"
        end
    end
    return fuelType
end

function changeVehicleFuelType(vehicle, fuelType)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    if vehicle and #(playerCoords - GetEntityCoords(vehicle)) < 5 then
        SetFuel(vehicle, 0.0)
        exports['lc_utils']:notify("info",Utils.translate("vehicle_tank_emptied"))
        TriggerServerEvent("lc_fuel:setVehicleFuelType", GetVehicleNumberPlateText(vehicle), fuelType)
    else
        exports['lc_utils']:notify("error",Utils.translate("vehicle_not_found"))
    end
end

function getVehicleDisplayFuelAmount(currentFuel, tankSize)
    local displayFuelAmount = currentFuel * tankSize / 100
    return displayFuelAmount
end

function getVehicleTankSize(vehicle)
    local vehicleHash = GetEntityModel(vehicle)
    if Config.FuelTankSize.perVehicleHash[vehicleHash] then
        return Config.FuelTankSize.perVehicleHash[vehicleHash]
    end
    return Config.FuelTankSize.perClass[GetVehicleClass(vehicle)] or 100
end

function GetPumpOffset(pump)
    local heightOffset = { forward = 0.0, right = 0.0, up = 2.1 }
    local pumpModel = GetEntityModel(pump)

    for _, v in pairs(Config.Electric.chargersProps) do
        if pumpModel == joaat(v.prop) then
            heightOffset = v.ropeOffset
        end
    end

    for _, v in pairs(Config.GasPumpProps) do
        if pumpModel == joaat(v.prop) then
            heightOffset = v.ropeOffset
        end
    end

    return heightOffset
end

function CreateRopeToPump(pumpCoords)
    local offset = GetPumpOffset(currentPump)

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
    end

    local forwardVector, rightVector, upVector, _ = GetEntityMatrix(currentPump)

    -- Adjust the offsets
    local forwardOffset = forwardVector * offset.forward
    local rightoffset = rightVector * offset.right
    local upOffset = upVector * offset.up
    local finalOffset = forwardOffset + rightoffset + upOffset

    local ropeObj = AddRope(pumpCoords.x + finalOffset.x, pumpCoords.y + finalOffset.y, pumpCoords.z + finalOffset.z, 0.0, 0.0, 0.0, 4.0, 1, 10.0, 0.0, 1.0, false, false, false, 1.0, true)
    while not ropeObj do
        Wait(0)
    end
    ActivatePhysics(ropeObj)
    Wait(100)

    local nozzlePos = GetOffsetFromEntityInWorldCoords(fuelNozzle, 0.0, -0.033, -0.195)
    ---@diagnostic disable-next-line: param-type-mismatch
    AttachEntitiesToRope(ropeObj, currentPump, fuelNozzle, pumpCoords.x + finalOffset.x, pumpCoords.y + finalOffset.y, pumpCoords.z + finalOffset.z, nozzlePos.x, nozzlePos.y, nozzlePos.z, 30.0, false, false, nil, nil)
    return ropeObj
end

function GetVehicles()
    return GetGamePool('CVehicle')
end

function GetClosestVehicle(coords, modelFilter)
    return GetClosestEntity(GetVehicles(), false, coords, modelFilter)
end

function GetClosestEntity(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = PlayerPedId()
        coords = GetEntityCoords(playerPed)
    end

    if modelFilter then
        filteredEntities = {}

        for _, entity in pairs(entities) do
            if modelFilter[GetEntityModel(entity)] then
                filteredEntities[#filteredEntities + 1] = entity
            end
        end
    end

    for k, entity in pairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
        end
    end

    return closestEntity, closestEntityDistance
end

function GetVehicleCapPos(vehicle)
    local closestCapPos
    local tanks = vehicleCapBoneList()
    for _, v in pairs(tanks) do
        local vehicleTank = GetEntityBoneIndexByName(vehicle, v)
        if vehicleTank ~= -1 then
            closestCapPos = GetWorldPositionOfEntityBone(vehicle, vehicleTank)
            break
        end
    end
    return closestCapPos
end

function Round(num, numDecimalPlaces)
    error("Do not use this")
end

function IsVehicleBlacklisted(vehicle)
    if vehicle and vehicle ~= 0 then
        local vehicleHash = GetEntityModel(vehicle)
        -- Blacklist electric vehicles if electric recharge is disabled
        if not Config.Electric.enabled and IsVehicleElectric(vehicle) then
            return true
        end

        -- Check if the vehicle is in the blacklist
        if Config.BlacklistedVehiclesHash[vehicleHash] then
            return true
        end
        return false
    end
    return true
end

function IsVehicleDiesel(vehicle)
    if vehicle and vehicle ~= 0 then
        local vehicleHash = GetEntityModel(vehicle)
        -- Check if the vehicle is in the diesel list
        if Config.DieselVehiclesHash[vehicleHash] then
            return true
        end
    end
    return false
end

function IsVehicleElectric(vehicle)
    if vehicle and vehicle ~= 0 then
        local vehicleHash = GetEntityModel(vehicle)
        -- Check if the vehicle is in the diesel list
        if Config.Electric.vehiclesListHash[vehicleHash] then
            return true
        end
    end
    return false
end

function GetClosestPump(coords, isElectric)
    local pump = nil
    local currentPumpModel = nil
    local pumpList = isElectric and Config.Electric.chargersProps or Config.GasPumpProps

    for i = 1, #pumpList do
        currentPumpModel = pumpList[i].prop
        pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, joaat(currentPumpModel), true, true, true)
        if pump ~= 0 then return pump, currentPumpModel end
    end

    return nil, nil
end

function createBlips()
    if Config.Blips.onlyShowNearestBlip then
        Citizen.CreateThread(function()
            local currentBlip = 0
            local currentBlipIndex = 0

            while true do
                local coords = GetEntityCoords(PlayerPedId())
                local closestBlipDistance = math.maxinteger
                local closestBlipCoords
                local closestBlipId

                for blipId, blipCoord in pairs(Config.Blips.locations) do
                    local distanceToBlip = #(coords - blipCoord)

                    if distanceToBlip < closestBlipDistance then
                        closestBlipDistance = distanceToBlip
                        closestBlipCoords = blipCoord
                        closestBlipId = blipId
                    end
                end

                if currentBlipIndex ~= closestBlipId then
                    if DoesBlipExist(currentBlip) then
                        Utils.Blips.removeBlip(currentBlip)
                    end

                    if closestBlipCoords then
                        currentBlip = Utils.Blips.createBlipForCoords(closestBlipCoords.x,closestBlipCoords.y,closestBlipCoords.z,Config.Blips.blipId,Config.Blips.color,Utils.translate('blip_text'),Config.Blips.scale,false)
                    end

                    currentBlipIndex = closestBlipId
                end

                Citizen.Wait(5000)
            end
        end)
    else
        local text = Utils.translate('blip_text')
        for _, blipCoords in pairs(Config.Blips.locations) do
            Utils.Blips.createBlipForCoords(blipCoords.x,blipCoords.y,blipCoords.z,Config.Blips.blipId,Config.Blips.color,text,Config.Blips.scale,false)
        end
    end
end

function convertConfigVehiclesDisplayNameToHash()
    Config.BlacklistedVehiclesHash = {}
    for _, value in pairs(Config.BlacklistedVehicles) do
        Config.BlacklistedVehiclesHash[joaat(value)] = true
    end
    Config.Electric.vehiclesListHash = {}
    for _, value in pairs(Config.Electric.vehiclesList) do
        Config.Electric.vehiclesListHash[joaat(value)] = true
    end
    Config.DieselVehiclesHash = {}
    for _, value in pairs(Config.DieselVehicles) do
        Config.DieselVehiclesHash[joaat(value)] = true
    end
    Config.FuelTankSize.perVehicleHash = {}
    for key, value in pairs(Config.FuelTankSize.perVehicle) do
        Config.FuelTankSize.perVehicleHash[joaat(key)] = value
    end
    Config.CustomVehicleParametersHash = {}
    Utils.Table.deepMerge(Config.HiddenCustomVehicleParameters, Config.CustomVehicleParameters)
    for key, value in pairs(Config.HiddenCustomVehicleParameters) do
        Config.CustomVehicleParametersHash[joaat(key)] = value
    end
    Config.CustomVehicleParametersHash.default = Config.CustomVehicleParameters.default -- Adds back the default
end

RegisterNetEvent('lc_fuel:Notify')
AddEventHandler('lc_fuel:Notify', function(type,message)
    exports['lc_utils']:notify(type,message)
end)

Citizen.CreateThread(function()
    Wait(1000)
    SetNuiFocus(false,false)
    SetNuiFocusKeepInput(false)
    FreezeEntityPosition(PlayerPedId(), false)

    Utils.loadLanguageFile(Lang)

    cachedTranslations = {
        open_refuel = Utils.translate('markers.open_refuel'),
        open_recharge = Utils.translate('markers.open_recharge'),
        interact_with_vehicle = Utils.translate('markers.interact_with_vehicle'),
        return_nozzle = Utils.translate('markers.return_nozzle'),
    }

    convertConfigVehiclesDisplayNameToHash()

    if Config.Blips and Config.Blips.enabled then
        createBlips()
    end

    -- Gas
    if Utils.Config.custom_scripts_compatibility.target == "disabled" then
        createGasMarkersThread()
    else
        createGasTargetsThread()
    end
    createCustomPumpModelsThread()

    -- Electrics
    if Config.Electric.enabled then
        CreateThread(function()
            createElectricZones()

            if Utils.Config.custom_scripts_compatibility.target == "disabled" then
                createElectricMarkersThread()
            else
                createElectricTargetsThread()
            end
        end)
    end

    -- Refuel
    if Utils.Config.custom_scripts_compatibility.target ~= "disabled" then
        createTargetForVehicleIteraction()
    end

    -- Other threads
    createFuelConsumptionThread()
    if Config.JerryCan.enabled and Utils.Config.custom_scripts_compatibility.target == "disabled" then
        createJerryCanThread()
    end

    if Config.DebugNozzleOffset then
        createDebugNozzleOffsetThread()
    end
end)

-- Debug nozzle offset functions
function GetVehiclePlayerIsLookingAt()
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    local maxDistance = 10.0

    local destCoords = camCoords + direction * maxDistance
    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destCoords.x, destCoords.y, destCoords.z, 10, playerPed, 0)
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and IsEntityAVehicle(entityHit) then
        return entityHit
    end
    return nil
end

function GetLookAtHitCoords()
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)

    local endCoords = vec3(
        camCoords.x + direction.x * 10.0,
        camCoords.y + direction.y * 10.0,
        camCoords.z + direction.z * 10.0
    )

    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, playerPed, 0)
    local _, hit, hitCoords = GetShapeTestResult(rayHandle)
    return hit, hitCoords
end

function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.cos(x)

    return vec3(
        -math.sin(z) * cosX,
        math.cos(z) * cosX,
        math.sin(x)
    )
end

-- Gets the offset from 'petrolcap' to the point you're looking at
function GetNozzleOffset(vehicle, hitCoords)
    -- World position of the bone
    local boneWorldPos = GetVehicleCapPos(vehicle)

    -- Directional vector from bone to hit point
    local direction = {
        x = hitCoords.x - boneWorldPos.x,
        y = hitCoords.y - boneWorldPos.y,
        z = hitCoords.z - boneWorldPos.z
    }

    -- Convert direction vector to vehicle-local offset
    local forwardVector, rightVector, upVector, _ = GetEntityMatrix(vehicle)

    local offset = {
        right = direction.x * rightVector.x + direction.y * rightVector.y + direction.z * rightVector.z,
        forward = direction.x * forwardVector.x + direction.y * forwardVector.y + direction.z * forwardVector.z,
        up = direction.x * upVector.x + direction.y * upVector.y + direction.z * upVector.z
    }

    return offset
end

if Config.EnableHUD then
    local function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
        SetTextFont(font)
        SetTextProportional(false)
        SetTextScale(sc, sc)
        SetTextJustification(jus)
        SetTextColour(r, g, b, a)
        SetTextDropShadow()
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x - 0.1+w, y - 0.02+h)
    end

    local mph = "0"
    local kmh = "0"
    local fuel = "0"
    local displayHud = false

    local x = 0.01135
    local y = 0.002

    Citizen.CreateThread(function()
        while true do
            local ped = PlayerPedId()

            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle)

                mph = tostring(math.ceil(speed * 2.236936))
                kmh = tostring(math.ceil(speed * 3.6))
                fuel = tostring(Utils.Math.round(GetVehicleFuelLevel(vehicle),2))

                displayHud = true
            else
                displayHud = false

                Citizen.Wait(500)
            end

            Citizen.Wait(50)
        end
    end)

    Citizen.CreateThread(function()
        while true do
            if displayHud then
                DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, mph, 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.174 - x, 0.77 - y, 0.005, 0.0028, 0.6, kmh, 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.2155 - x, 0.77 - y, 0.005, 0.0028, 0.6, fuel, 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.2615 - x, 0.77 - y, 0.005, 0.0028, 0.6, tostring(currentConsumption), 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.145 - x, 0.7765 - y, 0.005, 0.0028, 0.4, "mp/h              km/h                  Fuel                Consumption", 255, 255, 255, 255, 6, 1)
            else
                Citizen.Wait(50)
            end

            Citizen.Wait(0)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    deleteRopeAndNozzleProp()
end)

function deleteRopeAndNozzleProp()
    if DoesRopeExist(fuelRope) then
        RopeUnloadTextures()
        DeleteRope(fuelRope)
    end
    if DoesEntityExist(fuelNozzle) then
        requestNozzleOwnership()
        DeleteEntity(fuelNozzle)
        DeleteObject(fuelNozzle)
    end
end

function requestNozzleOwnership()
    NetworkRequestControlOfEntity(fuelNozzle)
    local start = GetGameTimer()
    while not NetworkHasControlOfEntity(fuelNozzle) and GetGameTimer() - start < 2000 do
        Wait(0)
        NetworkRequestControlOfEntity(fuelNozzle)
    end
    if not NetworkHasControlOfEntity(fuelNozzle) then
        print("Failed to gain control of fuel nozzle prop")
    end
end

function vehicleCapBoneList()
    return { "petrolcap", "petroltank", "petroltank_l", "petroltank_r", "wheel_lr", "wheel_lf", "engine", "chassis_dummy" }
end

-- Do not change this, use the Config.CustomVehicleParameters in config.lua
Config.HiddenCustomVehicleParameters = {
    -- Cars
    ["asbo"] = { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.21, up = 0.50} },
    ["blista"] = { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.21, up = 0.50} },
    ["brioso"] = { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.10, up = 0.60} },
    ["club"] = { distance = 1.2, nozzleOffset = { forward = -0.2, right = -0.13, up = 0.50} },
    ["kanjo"] = { distance = 1.2, nozzleOffset = { forward = -0.2, right = -0.17, up = 0.50} },
    ["issi2"] = { distance = 1.2, nozzleOffset = { forward = -0.2, right = -0.15, up = 0.50} },
    ["issi3"] = { distance = 1.2, nozzleOffset = { forward = -0.27, right = -0.13, up = 0.54} },
    ["issi4"] = { distance = 1.2, nozzleOffset = { forward = -0.27, right = -0.13, up = 0.70} },
    ["issi5"] = { distance = 1.2, nozzleOffset = { forward = -0.27, right = -0.13, up = 0.70} },
    ["issi6"] = { distance = 1.2, nozzleOffset = { forward = -0.27, right = -0.13, up = 0.70} },
    ["panto"] = { distance = 1.2, nozzleOffset = { forward = -0.10, right = -0.15, up = 0.65} },
    ["prairie"] = { distance = 1.2, nozzleOffset = { forward = -0.20, right = -0.20, up = 0.45} },
    ["rhapsody"] = { distance = 1.2, nozzleOffset = { forward = -0.20, right = -0.20, up = 0.45} },
    ["brioso2"] = { distance = 1.2, nozzleOffset = { forward = -0.25, right = -0.13, up = 0.40} },
    ["weevil"] = { distance = 1.2, nozzleOffset = { forward = -0.02, right = -0.03, up = 0.63} },
    ["issi7"] = { distance = 1.2, nozzleOffset = { forward = -0.03, right = -0.12, up = 0.57} },
    ["blista2"] = { distance = 1.2, nozzleOffset = { forward = -0.25, right = -0.23, up = 0.50} },
    ["blista3"] = { distance = 1.2, nozzleOffset = { forward = -0.25, right = -0.23, up = 0.50} },
    ["brioso3"] = { distance = 1.2, nozzleOffset = { forward = -0.25, right = -0.06, up = 0.40} },
    ["boor"] = { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.18, up = 0.50} },
    ["asea"] = { distance = 1.2, nozzleOffset = { forward = -0.28, right = -0.21, up = 0.50} },
    ["asterope"] = { distance = 1.2, nozzleOffset = { forward = -0.28, right = -0.16, up = 0.50} },
    ["cog55"] = { distance = 1.2, nozzleOffset = { forward = -0.44, right = -0.21, up = 0.45} },
    ["cognoscenti"] = { distance = 1.2, nozzleOffset = { forward = -0.44, right = -0.21, up = 0.45} },
    ["emperor"] = { distance = 1.2, nozzleOffset = { forward = -0.44, right = -0.22, up = 0.40} },
    ["fugitive"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.15, up = 0.40} },
    ["glendale"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.22, up = 0.40} },
    ["glendale2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.22, up = 0.30} },
    ["ingot"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.23, up = 0.45} },
    ["intruder"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.23, up = 0.40} },
    ["premier"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.16, up = 0.52} },
    ["primo"] = { distance = 1.2, nozzleOffset = { forward = -0.52, right = -0.18, up = 0.40} },
    ["primo2"] = { distance = 1.2, nozzleOffset = { forward = -0.52, right = -0.20, up = 0.35} },
    ["regina"] = { distance = 1.2, nozzleOffset = { forward = -0.52, right = -0.24, up = 0.40} },
    ["stafford"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.17, up = 0.50} },
    ["stanier"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.21, up = 0.40} },
    ["stratum"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.35} },
    ["stretch"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.21, up = 0.35} },
    ["superd"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.40} },
    ["tailgater"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.45} },
    ["warrener"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.45} },
    ["washington"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.22, up = 0.45} },
    ["tailgater2"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.14, up = 0.45} },
    ["cinquemila"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.21, up = 0.55} },
    ["astron"] = { distance = 1.2, nozzleOffset = { forward = -0.20, right = -0.22, up = 0.55} },
    ["baller7"] = { distance = 1.2, nozzleOffset = { forward = -0.62, right = -0.16, up = 0.60} },
    ["comet7"] = { distance = 1.2, nozzleOffset = { forward = -0.37, right = -0.19, up = 0.45} },
    ["deity"] = { distance = 1.2, nozzleOffset = { forward = -0.37, right = -0.21, up = 0.50} },
    ["jubilee"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.16, up = 0.60} },
    ["oracle"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.40} },
    ["schafter2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.45} },
    ["warrener2"] = { distance = 1.2, nozzleOffset = { forward = -0.02, right = -0.20, up = 0.40} },
    ["rhinehart"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.15, up = 0.50} },
    ["eudora"] = { distance = 1.2, nozzleOffset = { forward = 0.29, right = -0.38, up = 0.22} },

    ["rebla"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.19, up = 0.60} },
    ["baller"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.23, up = 0.60} },
    ["baller2"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.60} },
    ["baller3"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.60} },
    ["baller4"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.60} },
    ["baller5"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.60} },
    ["baller6"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.60} },
    ["bjxl"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.21, up = 0.60} },
    ["cavalcade"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.21, up = 0.65} },
    ["cavalcade2"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.21, up = 0.65} },
    ["contender"] = { distance = 1.2, nozzleOffset = { forward = 0.75, right = -0.17, up = 0.50} },
    ["dubsta"] = { distance = 1.2, nozzleOffset = { forward = 0.25, right = -0.17, up = 0.70} },
    ["dubsta2"] = { distance = 1.2, nozzleOffset = { forward = 0.25, right = -0.17, up = 0.70} },
    ["fq2"] = { distance = 1.2, nozzleOffset = { forward = -0.32, right = -0.23, up = 0.53} },
    ["granger"] = { distance = 1.2, nozzleOffset = { forward = 0.65, right = -0.27, up = 0.60} },
    ["granger2"] = { distance = 1.2, nozzleOffset = { forward = 0.45, right = -0.26, up = 0.60} },
    ["gresley"] = { distance = 1.2, nozzleOffset = { forward = 0.05, right = -0.17, up = 0.66} },
    ["habanero"] = { distance = 1.2, nozzleOffset = { forward = -0.47, right = -0.17, up = 0.50} },
    ["huntley"] = { distance = 1.2, nozzleOffset = { forward = 0.07, right = -0.24, up = 0.65} },
    ["landstalker"] = { distance = 1.2, nozzleOffset = { forward = 0.40, right = -0.23, up = 0.60} },
    ["landstalker2"] = { distance = 1.2, nozzleOffset = { forward = 0.25, right = -0.24, up = 0.60} },
    ["novak"] = { distance = 1.2, nozzleOffset = { forward = -0.25, right = -0.21, up = 0.60} },
    ["patriot"] = { distance = 1.2, nozzleOffset = { forward = 0.2, right = -0.22, up = 0.75} },
    ["patriot2"] = { distance = 1.2, nozzleOffset = { forward = 0.2, right = -0.22, up = 0.75} },
    ["patriot3"] = { distance = 1.2, nozzleOffset = { forward = 0.50, right = -0.29, up = 0.65} },
    ["radi"] = { distance = 1.2, nozzleOffset = { forward = -0.30, right = -0.17, up = 0.60} },
    ["rocoto"] = { distance = 1.2, nozzleOffset = { forward = -0.30, right = -0.20, up = 0.60} },
    ["seminole"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.20, up = 0.65} },
    ["seminole2"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.20, up = 0.55} },
    ["serrano"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.19, up = 0.60} },
    ["toros"] = { distance = 1.2, nozzleOffset = { forward = -0.26, right = -0.26, up = 0.68} },
    ["xls"] = { distance = 1.2, nozzleOffset = { forward = -0.0, right = -0.20, up = 0.65} },

    ["cogcabrio"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.50} },
    ["exemplar"] = { distance = 1.2, nozzleOffset = { forward = -0.27, right = -0.19, up = 0.45} },
    ["f620"] = { distance = 1.2, nozzleOffset = { forward = -0.29, right = -0.25, up = 0.40} },
    ["felon"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.18, up = 0.40} },
    ["felon2"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.18, up = 0.40} },
    ["jackal"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.11, up = 0.50} },
    ["oracle2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.15, up = 0.50} },
    ["sentinel"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.11, up = 0.50} },
    ["sentinel2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.11, up = 0.50} },
    ["windsor"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.15, up = 0.50} },
    ["windsor2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.15, up = 0.50} },
    ["zion"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.17, up = 0.50} },
    ["zion2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.17, up = 0.50} },
    ["previon"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.21, up = 0.50} },
    ["champion"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.11, up = 0.40} },
    ["futo"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.15, up = 0.40} },
    ["sentinel3"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.22, up = 0.30} },
    ["kanjosj"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.45} },
    ["postlude"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.15, up = 0.45} },
    ["tahoma"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.35} },
    ["broadway"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.35} },

    ["blade"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.31, up = 0.40} },
    ["buccaneer"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.28, up = 0.40} },
    ["chino"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.28, up = 0.35} },
    ["chino2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.25} },
    ["clique"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.21, up = 0.25} },
    ["coquette3"] = { distance = 1.2, nozzleOffset = { forward = 0.43, right = -0.31, up = 0.25} },
    ["deviant"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["dominator"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["dominator2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["dominator3"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.40} },
    ["dominator4"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.21, up = 0.40} },
    ["dominator7"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.40} },
    ["dominator8"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.40} },
    ["dukes"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.31, up = 0.40} },
    ["dukes2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.31, up = 0.40} },
    ["dukes3"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.25, up = 0.40} },
    ["faction"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.17, up = 0.40} },
    ["faction2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.16, up = 0.30} },
    ["faction3"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.16, up = 0.70} },
    ["ellie"] = { distance = 1.2, nozzleOffset = { forward = -0.30, right = -0.05, up = 0.67} },
    ["gauntlet"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.40} },
    ["gauntlet2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.40} },
    ["gauntlet3"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.25, up = 0.50} },
    ["gauntlet4"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.18, up = 0.45} },
    ["gauntlet5"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.25, up = 0.50} },
    ["hermes"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.31, up = 0.20} },
    ["hotknife"] = { distance = 1.2, nozzleOffset = { forward = 0.40, right = -0.00, up = 0.30} },
    ["hustler"] = { distance = 1.2, nozzleOffset = { forward = -0.62, right = 0.05, up = 0.20} },
    ["impaler"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.27, up = 0.35} },
    ["impaler2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.24, up = 0.35} },
    ["impaler3"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.22, up = 0.45} },
    ["impaler4"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.35} },
    ["imperator"] = { distance = 1.2, nozzleOffset = { forward = -0.05, right = -0.15, up = 0.65} },
    ["imperator2"] = { distance = 1.2, nozzleOffset = { forward = -0.05, right = -0.15, up = 0.65} },
    ["imperator3"] = { distance = 1.2, nozzleOffset = { forward = -0.05, right = -0.15, up = 0.65} },
    ["lurcher"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.30, up = 0.35} },
    ["nightshade"] = { distance = 1.2, nozzleOffset = { forward = -0.60, right = -0.07, up = 0.35} },
    ["phoenix"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.23, up = 0.35} },
    ["picador"] = { distance = 1.2, nozzleOffset = { forward = 0.75, right = -0.23, up = 0.45} },
    ["ratloader2"] = { distance = 1.2, nozzleOffset = { forward = 1.05, right = -0.07, up = 0.35} },
    ["ruiner"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.35} },
    ["ruiner2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.35} },
    ["sabregt"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.20, up = 0.35} },
    ["sabregt2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.20, up = 0.30} },
    ["slamvan"] = { distance = 1.2, nozzleOffset = { forward = 0.90, right = 0.03, up = 0.25} },
    ["slamvan2"] = { distance = 1.2, nozzleOffset = { forward = 0.90, right = -0.18, up = 0.30} },
    ["slamvan3"] = { distance = 1.2, nozzleOffset = { forward = 0.85, right = -0.03, up = 0.10} },
    ["stalion"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.35} },
    ["stalion2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.35} },
    ["tampa"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.20, up = 0.35} },
    ["tulip"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.23, up = 0.35} },
    ["vamos"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.25, up = 0.39} },
    ["vigero"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.22, up = 0.39} },
    ["virgo"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.22, up = 0.39} },
    ["virgo2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.28, up = 0.30} },
    ["virgo3"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.25, up = 0.30} },
    ["voodoo"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.29, up = 0.42} },
    ["yosemite"] = { distance = 1.2, nozzleOffset = { forward = 1.20, right = -0.29, up = 0.25} },
    ["yosemite2"] = { distance = 1.2, nozzleOffset = { forward = 1.22, right = -0.13, up = 0.35} },
    ["buffalo4"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.22, up = 0.50} },
    ["manana"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.25, up = 0.30} },
    ["manana2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.25, up = 0.30} },
    ["tampa2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.10, up = 0.30} },
    ["ruiner4"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.19, up = 0.35} },
    ["vigero2"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.50} },
    ["weevil2"] = { distance = 1.2, nozzleOffset = { forward = 1.90, right = 0.15, up = 0.25} },
    ["buffalo5"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.50} },
    ["tulip2"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.24, up = 0.35} },
    ["clique2"] = { distance = 1.2, nozzleOffset = { forward = 0.05, right = -0.26, up = 0.60} },
    ["brigham"] = { distance = 1.2, nozzleOffset = { forward = 0.15, right = -0.30, up = 0.40} },
    ["greenwood"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.21, up = 0.50} },

    ["ardent"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.19, up = 0.35} },
    ["btype"] = { distance = 1.2, nozzleOffset = { forward = 0.25, right = -0.05, up = 0.78} },
    ["btype2"] = { distance = 1.2, nozzleOffset = { forward = 0.36, right = 0.07, up = 0.55} },
    ["btype3"] = { distance = 1.2, nozzleOffset = { forward = 0.25, right = -0.05, up = 0.78} },
    ["casco"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.21, up = 0.30} },
    ["deluxo"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.13, up = 0.40} },
    ["dynasty"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.21, up = 0.40} },
    ["fagaloa"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.21, up = 0.35} },
    ["feltzer3"] = { distance = 1.2, nozzleOffset = { forward = -0.31, right = -0.13, up = 0.55} },
    ["gt500"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.19, up = 0.25} },
    ["infernus2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.27, up = 0.35} },
    ["jb700"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.21, up = 0.35} },
    ["jb7002"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.21, up = 0.35} },
    ["mamba"] = { distance = 1.2, nozzleOffset = { forward = -0.30, right = -0.13, up = 0.50} },
    ["michelli"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.18, up = 0.30} },
    ["monroe"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.21, up = 0.30} },
    ["nebula"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.30} },
    ["peyote"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.26, up = 0.30} },
    ["peyote3"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.26, up = 0.30} },
    ["pigalle"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.30} },
    ["rapidgt3"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.30} },
    ["retinue"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.30} },
    ["retinue2"] = { distance = 1.2, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.30} },
    ["savestra"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.15, up = 0.40} },
    ["stinger"] = { distance = 1.2, nozzleOffset = { forward = -0.02, right = -0.13, up = 0.65} },
    ["stingergt"] = { distance = 1.2, nozzleOffset = { forward = -0.55, right = -0.20, up = 0.30} },
    ["stromberg"] = { distance = 1.2, nozzleOffset = { forward = -0.35, right = -0.23, up = 0.35} },
    ["swinger"] = { distance = 1.2, nozzleOffset = { forward = 0.45, right = -0.28, up = 0.25} },
    ["torero"] = { distance = 1.2, nozzleOffset = { forward = 0.75, right = -0.21, up = 0.35} },
    ["tornado"] = { distance = 1.2, nozzleOffset = { forward = 0.45, right = -0.28, up = 0.25} },
    ["tornado2"] = { distance = 1.2, nozzleOffset = { forward = 0.45, right = -0.28, up = 0.25} },
    ["tornado5"] = { distance = 1.2, nozzleOffset = { forward = 0.45, right = -0.28, up = 0.25} },
    ["turismo2"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.23, up = 0.40} },
    ["viseris"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.18, up = 0.40} },
    ["z190"] = { distance = 1.2, nozzleOffset = { forward = -0.68, right = -0.10, up = 0.47} },
    ["ztype"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.23, up = 0.30} },
    ["zion3"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.23, up = 0.30} },
    ["cheburek"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.20, up = 0.30} },
    ["toreador"] = { distance = 1.2, nozzleOffset = { forward = -0.40, right = -0.22, up = 0.35} },
    ["peyote2"] = { distance = 1.2, nozzleOffset = { forward = -0.50, right = -0.28, up = 0.30} },
    ["coquette2"] = { distance = 1.2, nozzleOffset = { forward = 0.43, right = -0.24, up = 0.25} },

    ["alpha"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.21, up = 0.40} },
    ["banshee"] = { distance = 1.3, nozzleOffset = { forward = -0.55, right = -0.09, up = 0.40} },
    ["bestiagts"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.25, up = 0.45} },
    ["buffalo"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.35} },
    ["buffalo2"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.35} },
    ["carbonizzare"] = { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.27, up = 0.50} },
    ["comet2"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.35} },
    ["comet3"] = { distance = 1.3, nozzleOffset = { forward = -0.52, right = -0.07, up = 0.20} },
    ["comet4"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.20, up = 0.35} },
    ["comet5"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.35} },
    ["coquette"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.28, up = 0.25} },
    ["coquette4"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.28, up = 0.25} },
    ["drafter"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.18, up = 0.45} },
    ["elegy"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.28, up = 0.30} },
    ["elegy2"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.18, up = 0.50} },
    ["feltzer2"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.15, up = 0.45} },
    ["flashgt"] = { distance = 1.3, nozzleOffset = { forward = -0.31, right = -0.26, up = 0.50} },
    ["furoregt"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.50} },
    ["gb200"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.20, up = 0.40} },
    ["komoda"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["italigto"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.27, up = 0.40} },
    ["jugular"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.16, up = 0.55} },
    ["jester"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.23, up = 0.35} },
    ["jester2"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.23, up = 0.35} },
    ["jester3"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.16, up = 0.40} },
    ["kuruma"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.19, up = 0.40} },
    ["kuruma2"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.19, up = 0.40} },
    ["locust"] = { distance = 1.3, nozzleOffset = { forward = 0.44, right = 0.00, up = 0.61} },
    ["lynx"] = { distance = 1.3, nozzleOffset = { forward = 0.43, right = -0.24, up = 0.40} },
    ["massacro"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.21, up = 0.42} },
    ["massacro2"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.21, up = 0.42} },
    ["neo"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.23, up = 0.42} },
    ["ninef"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.24, up = 0.35} },
    ["ninef2"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.24, up = 0.35} },
    ["omnis"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.27, up = 0.31} },
    ["paragon"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.25, up = 0.40} },
    ["pariah"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.19, up = 0.45} },
    ["penumbra"] = { distance = 1.3, nozzleOffset = { forward = -0.25, right = -0.19, up = 0.50} },
    ["penumbra2"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.40} },
    ["rapidgt"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.17, up = 0.40} },
    ["rapidgt2"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.17, up = 0.40} },
    ["raptor"] = { distance = 1.3, nozzleOffset = { forward = -0.20, right = -0.40, up = 0.25} },
    ["revolter"] = { distance = 1.3, nozzleOffset = { forward = -0.55, right = -0.17, up = 0.45} },
    ["ruston"] = { distance = 1.3, nozzleOffset = { forward = 0.53, right = -0.00, up = 0.53} },
    ["schafter3"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.40} },
    ["schafter4"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.40} },
    ["schlagen"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.40} },
    ["seven70"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.23, up = 0.30} },
    ["specter"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.23, up = 0.30} },
    ["streiter"] = { distance = 1.3, nozzleOffset = { forward = -0.55, right = -0.08, up = 0.50} },
    ["sugoi"] = { distance = 1.3, nozzleOffset = { forward = -0.25, right = -0.15, up = 0.50} },
    ["sultan"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["sultan2"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["surano"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.26, up = 0.40} },
    ["tropos"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.08, up = 0.40} },
    ["verlierer2"] = { distance = 1.3, nozzleOffset = { forward = 1.60, right = -0.19, up = 0.30} },
    ["vstr"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.17, up = 0.55} },
    ["zr350"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.21, up = 0.35} },
    ["calico"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.16, up = 0.45} },
    ["futo2"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.19, up = 0.35} },
    ["euros"] = { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.15, up = 0.55} },
    ["remus"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.16, up = 0.45} },
    ["comet6"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.35} },
    ["growler"] = { distance = 1.3, nozzleOffset = { forward = -0.20, right = -0.23, up = 0.45} },
    ["vectre"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.17, up = 0.45} },
    ["cypher"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.21, up = 0.45} },
    ["sultan3"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.40} },
    ["rt3000"] = { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.17, up = 0.45} },
    ["sultanrs"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.13, up = 0.40} },
    ["visione"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.10, up = 0.40} },
    ["cheetah2"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.20, up = 0.35} },
    ["stingertt"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.25, up = 0.35} },
    ["sentinel4"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.35} },
    ["sm722"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.35} },
    ["tenf"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.23, up = 0.43} },
    ["tenf2"] = { distance = 1.3, nozzleOffset = { forward = 0.43, right = -0.15, up = 0.43} },
    ["everon2"] = { distance = 1.3, nozzleOffset = { forward = -1.03, right = -0.24, up = 0.50} },
    ["issi8"] = { distance = 1.3, nozzleOffset = { forward = -0.20, right = -0.21, up = 0.55} },
    ["corsita"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.24, up = 0.30} },
    ["gauntlet6"] = { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.21, up = 0.31} },
    ["coureur"] = { distance = 1.3, nozzleOffset = { forward = -0.10, right = -0.22, up = 0.45} },
    ["r300"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.26, up = 0.40} },
    ["panthere"] = { distance = 1.3, nozzleOffset = { forward = -0.30, right = -0.14, up = 0.40} },

    ["adder"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.19, up = 0.50} },
    ["autarch"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.23, up = 0.30} },
    ["banshee2"] = { distance = 1.3, nozzleOffset = { forward = -0.55, right = -0.09, up = 0.40} },
    ["bullet"] = { distance = 1.3, nozzleOffset = { forward = -0.00, right = -0.30, up = 0.05} },
    ["cheetah"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.31, up = 0.35} },
    ["entity2"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.27, up = 0.35} },
    ["entityxf"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.31, up = 0.35} },
    ["emerus"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.28, up = 0.35} },
    ["fmj"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.23, up = 0.30} },
    ["furia"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.26, up = 0.35} },
    ["gp1"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.27, up = 0.30} },
    ["infernus"] = { distance = 1.3, nozzleOffset = { forward = 0.91, right = -0.14, up = 0.65} },
    ["italigtb"] = { distance = 1.3, nozzleOffset = { forward = 0.25, right = -0.20, up = 0.35} },
    ["italigtb2"] = { distance = 1.3, nozzleOffset = { forward = 0.25, right = -0.20, up = 0.40} },
    ["krieger"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.21, up = 0.25} },
    ["le7b"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.35, up = 0.25} },
    ["nero"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.29, up = 0.25} },
    ["nero2"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.29, up = 0.25} },
    ["osiris"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.27, up = 0.25} },
    ["penetrator"] = { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.25, up = 0.25} },
    ["pfister811"] = { distance = 1.3, nozzleOffset = { forward = 0.75, right = -0.28, up = 0.35} },
    ["prototipo"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.27, up = 0.35} },
    ["reaper"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.15, up = 0.35} },
    ["s80"] = { distance = 1.3, nozzleOffset = { forward = 0.40, right = -0.31, up = 0.30} },
    ["sc1"] = { distance = 1.3, nozzleOffset = { forward = 0.40, right = -0.25, up = 0.30} },
    ["sheava"] = { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.17, up = 0.35} },
    ["t20"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.27, up = 0.30} },
    ["taipan"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.25, up = 0.30} },
    ["tempesta"] = { distance = 1.3, nozzleOffset = { forward = 0.25, right = -0.10, up = 0.60} },
    ["thrax"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.22, up = 0.30} },
    ["tigon"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.27, up = 0.30} },
    ["turismor"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.28, up = 0.30} },
    ["tyrant"] = { distance = 1.3, nozzleOffset = { forward = 0.30, right = -0.29, up = 0.50} },
    ["tyrus"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.26, up = 0.30} },
    ["vacca"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.32, up = 0.35} },
    ["vagner"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.29, up = 0.35} },
    ["xa21"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.27, up = 0.35} },
    ["zentorno"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.29, up = 0.35} },
    ["zorrusso"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.27, up = 0.35} },
    ["ignus"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.32, up = 0.35} },
    ["zeno"] = { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.24, up = 0.35} },
    ["deveste"] = { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.21, up = 0.25} },
    ["lm87"] = { distance = 1.3, nozzleOffset = { forward = 0.40, right = -0.34, up = 0.25} },
    ["torero2"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.28, up = 0.35} },
    ["entity3"] =  { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.27, up = 0.25} },
    ["virtue"] =  { distance = 1.3, nozzleOffset = { forward = 0.45, right = -0.19, up = 0.35} },

    ["bfinjection"] =  { distance = 1.3, nozzleOffset = { forward = 0.60, right = 0.02, up = 0.35} },
    ["bifta"] =  { distance = 1.3, nozzleOffset = { forward = 0.03, right = -0.65, up = 0.10} },

    -- offroad
    ["blazer"] =  { distance = 1.3, nozzleOffset = { forward = -0.08, right = -0.29, up = 0.20} },
    ["blazer2"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.25, up = 0.25} },
    ["blazer3"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.25, up = 0.15} },
    ["blazer4"] =  { distance = 1.3, nozzleOffset = { forward = -0.00, right = -0.22, up = 0.12} },
    ["blazer5"] =  { distance = 1.3, nozzleOffset = { forward = -0.10, right = -0.55, up = 0.25} },
    ["brawler"] =  { distance = 1.3, nozzleOffset = { forward = -0.16, right = -0.13, up = 0.90} },
    ["caracara"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.16, up = 0.80} },
    ["caracara2"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.16, up = 0.80} },
    ["dubsta3"] =  { distance = 1.3, nozzleOffset = { forward = -0.75, right = -0.97, up = 0.40} },
    ["dune"] =  { distance = 1.3, nozzleOffset = { forward = 0.05, right = -0.65, up = 0.05} },
    ["everon"] =  { distance = 1.3, nozzleOffset = { forward = -0.80, right = -0.04, up = 0.80} },
    ["freecrawler"] =  { distance = 1.3, nozzleOffset = { forward = -0.10, right = -0.20, up = 1.00} },
    ["hellion"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.17, up = 0.40} },
    ["kalahari"] =  { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.17, up = 0.40} },
    ["kamacho"] =  { distance = 1.3, nozzleOffset = { forward = 1.05, right = -0.02, up = 0.60} },
    ["mesa3"] =  { distance = 1.3, nozzleOffset = { forward = 0.25, right = 0.02, up = 0.85} },
    ["outlaw"] =  { distance = 1.3, nozzleOffset = { forward = 0.60, right = -0.13, up = 0.70} },
    ["rancherxl"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.23, up = 0.50} },
    ["rebel2"] =  { distance = 1.3, nozzleOffset = { forward = 1.10, right = -0.09, up = 0.55} },
    ["riata"] =  { distance = 1.3, nozzleOffset = { forward = 0.90, right = -0.02, up = 0.80} },
    ["sandking"] =  { distance = 1.3, nozzleOffset = { forward = 0.90, right = -0.17, up = 0.70} },
    ["sandking2"] =  { distance = 1.3, nozzleOffset = { forward = 0.90, right = -0.17, up = 0.70} },
    ["trophytruck"] =  { distance = 1.3, nozzleOffset = { forward = 0.90, right = -0.10, up = 0.70} },
    ["trophytruck2"] =  { distance = 1.3, nozzleOffset = { forward = 0.90, right = -0.10, up = 0.70} },
    ["vagrant"] =  { distance = 1.3, nozzleOffset = { forward = 0.35, right = 0.15, up = 0.25} },
    ["verus"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.30, up = 0.08} },
    ["winky"] = { distance = 1.3, nozzleOffset = { forward = -1.00, right = -0.19, up = 0.50} },
    ["yosemite3"] = { distance = 1.3, nozzleOffset = { forward = 0.83, right = -0.19, up = 0.50} },
    ["mesa"] =  { distance = 1.3, nozzleOffset = { forward = 0.30, right = -0.11, up = 0.66} },
    ["ratel"] =  { distance = 1.3, nozzleOffset = { forward = 0.61, right = 0.16, up = 1.11} },
    ["l35"] =  { distance = 1.3, nozzleOffset = { forward = 0.80, right = -0.17, up = 0.55} },
    ["monstrociti"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.23, up = 0.45} },
    ["draugur"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.16, up = 0.80} },

    -- truck
    ["guardian"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.16, up = 0.40} },
    ["mixer2"] =  { distance = 1.3, nozzleOffset = { forward = 0.0, right = 0.11, up = -0.06} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["tiptruck2"] =  { distance = 3.5, nozzleOffset = { forward = 2.00, right = -2.25, up = -0.24} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["tiptruck"] =  { distance = 1.3, nozzleOffset = { forward = 0.01, right = -0.19, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["rubble"] =  { distance = 1.3, nozzleOffset = { forward = 0.01, right = -0.19, up = 0.04} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["mixer"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.23, up = 0.04} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["flatbed"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.23, up = 0.04} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dump"] =  { distance = 1.3, nozzleOffset = { forward = 0.27, right = -0.57, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["bulldozer"] =  { distance = 1.3, nozzleOffset = { forward = 0.70, right = -0.25, up = 0.80} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["handler"] =  { distance = 1.3, nozzleOffset = { forward = 0.88, right = -0.52, up = 0.88} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cutter"] =  { distance = 1.3, nozzleOffset = { forward = 0.95, right = -0.42, up = 0.30} , nozzleRotation = { x = 0, y = 0, z = 0} },

    -- utillity
    ["slamtruck"] =  { distance = 1.3, nozzleOffset = { forward = 0.70, right = -0.28, up = 0.26} },
    ["utillitruck"] = { distance = 2.0, nozzleOffset = { forward = -0.80, right = -1.25, up = 0.50} },
    ["utillitruck2"] = { distance = 2.0, nozzleOffset = { forward = -0.80, right = -1.25, up = 0.50} },
    ["utillitruck3"] = { distance = 2.0, nozzleOffset = { forward = -0.40, right = -0.30, up = 0.50} },
    ["tractor"] = { distance = 2.0, nozzleOffset = { forward = 1.50, right = 0.27, up = 0.30} },
    ["tractor2"] = { distance = 2.0, nozzleOffset = { forward = 1.60, right = 0.05, up = 0.20} },
    ["tractor3"] = { distance = 2.0, nozzleOffset = { forward = 1.60, right = 0.05, up = 0.20} },
    ["towtruck"] = { distance = 2.0, nozzleOffset = { forward = -0.45, right = -0.30, up = 0.10} },
    ["towtruck2"] = { distance = 2.0, nozzleOffset = { forward = 0.85, right = 0.05, up = 0.50} },
    ["scrap"] = { distance = 2.0, nozzleOffset = { forward = -0.52, right = -0.05, up = -0.05} },
    ["sadler"] =  { distance = 1.3, nozzleOffset = { forward = 1.14, right = -0.22, up = 0.70} },
    ["ripley"] =  { distance = 2.0, nozzleOffset = { forward = -0.95, right = -0.48, up = 0.40} },
    ["mower"] =  { distance = 2.0, nozzleOffset = { forward = 1.00, right = 0.10, up = 0.63} },
    ["forklift"] =  { distance = 1.3, nozzleOffset = { forward = 0.05, right = -0.27, up = -0.40} },
    ["docktug"] = { distance = 2.5, nozzleOffset = { forward = 0.0, right = -0.25, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },

    -- van
    ["bison"] =  { distance = 1.3, nozzleOffset = { forward = 0.70, right = -0.28, up = 0.26} },
    ["bobcatxl"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.28, up = 0.35} },
    ["burrito3"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.25, up = 0.35} },
    ["gburrito2"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.22, up = 0.35} },
    ["rumpo"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.25, up = 0.35} },
    ["journey"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.34, up = 0.45} },
    ["minivan"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.20, up = 0.45} },
    ["minivan2"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.20, up = 0.45} },
    ["paradise"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.23, up = 0.45} },
    ["rumpo3"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.23, up = 0.45} },
    ["speedo"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.24, up = 0.45} },
    ["speedo4"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.24, up = 0.45} },
    ["surfer"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.29, up = 0.45} },
    ["youga3"] =  { distance = 1.3, nozzleOffset = { forward = 0.55, right = -0.18, up = 0.45} },
    ["youga"] =  { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.23, up = 0.45} },
    ["youga2"] =  { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.25, up = 0.40} },
    ["youga4"] =  { distance = 1.3, nozzleOffset = { forward = 0.35, right = -0.30, up = 0.40} },
    ["moonbeam"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.28, up = 0.40} },
    ["moonbeam2"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.24, up = 0.40} },
    ["boxville"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.24, up = 0.40} },
    ["boxville2"] =  { distance = 1.3, nozzleOffset = { forward = -2.20, right = -0.30, up = 0.05} },
    ["boxville3"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.24, up = 0.40} },
    ["boxville4"] =  { distance = 1.3, nozzleOffset = { forward = -2.20, right = -0.30, up = 0.05} },
    ["boxville5"] =  { distance = 1.3, nozzleOffset = { forward = -2.20, right = -0.30, up = 0.05} },
    ["pony"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.24, up = 0.40} },
    ["pony2"] =  { distance = 1.3, nozzleOffset = { forward = 0.40, right = -0.26, up = 0.40} },
    ["journey2"] =  { distance = 1.3, nozzleOffset = { forward = -0.65, right = -0.34, up = 0.45} },
    ["surfer3"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.29, up = 0.45} },
    ["speedo5"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.24, up = 0.45} },
    ["mule2"] =  { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.35, up = 0.75} },
    ["taco"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.24, up = 0.45} },


    -- Lspd, ems ....
    ["riot"] =  { distance = 2.5, nozzleOffset = { forward = -0.80, right = -1.30, up = 0.30} },
    ["riot2"] = { distance = 1.3, nozzleOffset = { forward = -0.70, right = -0.09, up = 0.65} },
    ["pbus"] = { distance = 1.3, nozzleOffset = { forward = -0.70, right = -0.30, up = 0.65} },
    ["police"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.17, up = 0.50} },
    ["police2"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.24, up = 0.50} },
    ["police3"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.17, up = 0.50} },
    ["police4"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.17, up = 0.50} },
    ["sheriff"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.17, up = 0.50} },
    ["sheriff2"] = { distance = 1.3, nozzleOffset = { forward = 0.70, right = -0.28, up = 0.60} },
    ["policeold1"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.24, up = 0.60} },
    ["policeold2"] = { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.16, up = 0.40} },
    ["policet"] = { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.26, up = 0.60} },
    ["policeb"] = { distance = 1.3, nozzleOffset = { forward = -0.18, right = -0.18, up = 0.10}, nozzleRotation = { x = 0, y = 0, z = 60} },
    ["polmav"] = { distance = 3.0, nozzleOffset = { forward = 0.12, right = -0.60, up = -0.45}, nozzleRotation = { x = 0, y = 0, z = 20} },
    ["ambulance"] = { distance = 1.3, nozzleOffset = { forward = 2.95, right = -0.08, up = 0.50} },
    ["firetruk"] =  { distance = 1.3, nozzleOffset = { forward = 0.50, right = -0.32, up = 0.70} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["lguard"] = { distance = 1.3, nozzleOffset = { forward = 0.67, right = -0.27, up = 0.57} },
    ["pranger"] = { distance = 1.3, nozzleOffset = { forward = 0.67, right = -0.27, up = 0.57} },
    ["fbi"] = { distance = 1.3, nozzleOffset = { forward = -0.45, right = -0.24, up = 0.40} },
    ["fbi2"] = { distance = 1.3, nozzleOffset = { forward = 0.67, right = -0.27, up = 0.57} },
    ["predator"] = { distance = 3.5, nozzleOffset = { forward = 1.80, right = 1.58, up = 0.17}, nozzleRotation = { x = 0, y = 0, z = 180} },

    -- Military
    ["apc"] = { distance = 2.5, nozzleOffset = { forward = -0.80, right = -1.00, up = 1.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["barracks"] =  { distance = 3.5, nozzleOffset = { forward = 0.00, right = -0.25, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["barracks2"] =  { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.28, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["barracks3"] =  { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.16, up = -0.03} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["chernobog"] =  { distance = 2.5, nozzleOffset = { forward = 3.70, right = -0.20, up = 0.22} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["crusader"] =  { distance = 1.5, nozzleOffset = { forward = 0.25, right = -0.11, up = 0.65} },
    ["halftrack"] =  { distance = 1.5, nozzleOffset = { forward = -0.60, right = -0.30, up = 0.90} },
    ["khanjali"] =  { distance = 1.5, nozzleOffset = { forward = -0.55, right = -0.80, up = 0.95} },
    ["rhino"] =  { distance = 1.5, nozzleOffset = { forward = -0.05, right = -0.52, up = 1.00} },
    ["scarab"] =  { distance = 1.5, nozzleOffset = { forward = 0.60, right = 0.15, up = 1.08} },
    ["terbyte"] = { distance = 1.5, nozzleOffset = { forward = -0.700, right = -0.47, up = 0.65} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["vetir"] = { distance = 3.0, nozzleOffset = { forward = 1.25, right = 1.95, up = 0.40} , nozzleRotation = { x = 0, y = 0, z = 180} },

    ["thruster"] =  { distance = 1.5, nozzleOffset = { forward = -0.10, right = 0.40, up = 1.25} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["minitank"] =  { distance = 1.5, nozzleOffset = { forward = 0.05, right = -0.05, up = 0.49} },

    -- Electric cars
    ["voltic"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.14, up = 0.45} },
    ["voltic2"] =  { distance = 1.3, nozzleOffset = { forward = -0.12, right = 0.12, up = 0.57} },
    ["caddy"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.09, up = 0.53} },
    ["caddy2"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.09, up = 0.35} },
    ["caddy3"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.09, up = 0.35} },
    ["surge"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.14, up = 0.45} },
    ["iwagen"] =  { distance = 1.3, nozzleOffset = { forward = -0.40, right = -0.16, up = 0.50} },
    ["raiden"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.13, up = 0.50} },
    ["airtug"] =  { distance = 1.3, nozzleOffset = { forward = -0.20, right = -0.18, up = 0.47} },
    ["neon"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.16, up = 0.50} },
    ["omnisegt"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.16, up = 0.40} },
    ["cyclone"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.16, up = 0.45} },
    ["tezeract"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.16, up = 0.48} },
    ["imorgon"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.16, up = 0.48} },
    ["dilettante"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.14, up = 0.48} },
    ["dilettante2"] =  { distance = 1.3, nozzleOffset = { forward = -0.05, right = -0.14, up = 0.48} },
    ["khamelion"] =  { distance = 1.3, nozzleOffset = { forward = -0.35, right = -0.20, up = 0.48} },

    ["rcbandito"] =  { distance = 1.3, nozzleOffset = { forward = -0.12, right = 0.12, up = 0.22} },


    -- Motorcycles
    ["akuma"] = { distance = 1.1, nozzleOffset = { forward = 0.01, right = -0.20, up = 0.20} },
    ["avarus"] = { distance = 1.1, nozzleOffset = { forward = -0.22, right = 0.03, up = 0.11} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["bagger"] = { distance = 1.1, nozzleOffset = { forward = -0.26, right = 0.03, up = 0.11} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["bati"] = { distance = 1.1, nozzleOffset = { forward = -0.15, right = -0.25, up = 0.20} },
    ["bati2"] = { distance = 1.1, nozzleOffset = { forward = -0.15, right = -0.24, up = 0.20} },
    ["bf400"] = { distance = 1.1, nozzleOffset = { forward = -0.05, right = -0.24, up = 0.29} },
    ["carbonrs"] = { distance = 1.1, nozzleOffset = { forward = 0.01, right = -0.22, up = 0.20} },
    ["chimera"] = { distance = 1.1, nozzleOffset = { forward = -0.22, right = 0.00, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["cliffhanger"] = { distance = 1.1, nozzleOffset = { forward = -0.33, right = 0.05, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["daemon"] = { distance = 1.1, nozzleOffset = { forward = -0.17, right = 0.03, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["daemon2"] = { distance = 1.1, nozzleOffset = { forward = -0.17, right = 0.03, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["defiler"] = { distance = 1.1, nozzleOffset = { forward = 0.09, right = -0.23, up = 0.20} },
    ["deathbike"] = { distance = 1.1, nozzleOffset = { forward = -0.17, right = 0.03, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["deathbike2"] = { distance = 1.1, nozzleOffset = { forward = -0.25, right = 0.03, up = 0.07} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["deathbike3"] = { distance = 1.1, nozzleOffset = { forward = -0.17, right = 0.03, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["diablous"] = { distance = 1.1, nozzleOffset = { forward = -0.27, right = 0.06, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["diablous2"] = { distance = 1.1, nozzleOffset = { forward = -0.27, right = 0.03, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["double"] = { distance = 1.1, nozzleOffset = { forward = 0.01, right = -0.22, up = 0.20} },
    ["enduro"] = { distance = 1.1, nozzleOffset = { forward = -0.05, right = -0.17, up = 0.25} },
    ["esskey"] = { distance = 1.1, nozzleOffset = { forward = -0.05, right = -0.20, up = 0.20} },
    ["faggio"] = { distance = 1.1, nozzleOffset = { forward = 0.20, right = -0.28, up = 0.30} },
    ["faggio2"] = { distance = 1.1, nozzleOffset = { forward = 0.20, right = 0.25, up = -0.10} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["faggio3"] = { distance = 1.1, nozzleOffset = { forward = 0.20, right = 0.25, up = -0.10} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["fcr"] = { distance = 1.1, nozzleOffset = { forward = -0.03, right = -0.21, up = 0.10} },
    ["gargoyle"] = { distance = 1.1, nozzleOffset = { forward = -0.26, right = 0.03, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["hakuchou"] = { distance = 1.1, nozzleOffset = { forward = 0.05, right = -0.17, up = 0.10} },
    ["hakuchou2"] = { distance = 1.1, nozzleOffset = { forward = 0.00, right = -0.19, up = 0.10} },
    ["hexer"] = { distance = 1.1, nozzleOffset = { forward = -0.17, right = 0.04, up = 0.20} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["innovation"] = { distance = 1.1, nozzleOffset = { forward = -0.23, right = 0.02, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["lectro"] = { distance = 1.1, nozzleOffset = { forward = -0.12, right = -0.20, up = 0.20} },
    ["manchez"] = { distance = 1.1, nozzleOffset = { forward = -0.04, right = -0.20, up = 0.10} },
    ["nemesis"] = { distance = 1.1, nozzleOffset = { forward = -0.03, right = -0.17, up = 0.10} },
    ["nightblade"] = { distance = 1.1, nozzleOffset = { forward = -0.27, right = 0.05, up = 0.14} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["oppressor"] = { distance = 1.1, nozzleOffset = { forward = -0.27, right = 0.05, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["pcj"] = { distance = 1.1, nozzleOffset = { forward = 0.04, right = -0.20, up = 0.20} },
    ["ratbike"] = { distance = 1.1, nozzleOffset = { forward = -0.22, right = 0.03, up = 0.11} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["ruffian"] = { distance = 1.1, nozzleOffset = { forward = 0.04, right = -0.19, up = 0.20} },
    ["sanchez"] = { distance = 1.1, nozzleOffset = { forward = -0.05, right = -0.22, up = 0.25} },
    ["sanchez2"] = { distance = 1.1, nozzleOffset = { forward = -0.05, right = -0.22, up = 0.25} },
    ["sanctus"] = { distance = 1.1, nozzleOffset = { forward = -0.22, right = 0.03, up = 0.08} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["shotaro"] = { distance = 1.1, nozzleOffset = { forward = 0.06, right = -0.25, up = 0.20} },
    ["sovereign"] = { distance = 1.1, nozzleOffset = { forward = -0.07, right = -0.23, up = 0.15} },
    ["stryder"] = { distance = 1.1, nozzleOffset = { forward = 0.06, right = -0.20, up = 0.15} },
    ["thrust"] = { distance = 1.1, nozzleOffset = { forward = -0.02, right = -0.25, up = 0.15} },
    ["vader"] = { distance = 1.1, nozzleOffset = { forward = 0.10, right = -0.25, up = 0.20} },
    ["vindicator"] = { distance = 1.1, nozzleOffset = { forward = -0.02, right = -0.25, up = 0.15} },
    ["vortex"] = { distance = 1.1, nozzleOffset = { forward = -0.02, right = -0.20, up = 0.12} },
    ["wolfsbane"] = { distance = 1.1, nozzleOffset = { forward = -0.22, right = 0.03, up = 0.11} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["zombiea"] = { distance = 1.1, nozzleOffset = { forward = -0.14, right = 0.03, up = 0.11} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["zombieb"] = { distance = 1.1, nozzleOffset = { forward = -0.21, right = 0.03, up = 0.15} , nozzleRotation = { x = 0, y = 0, z = 90} },
    ["manchez2"] = { distance = 1.1, nozzleOffset = { forward = -0.04, right = -0.22, up = 0.10} },
    ["shinobi"] = { distance = 1.1, nozzleOffset = { forward = -0.04, right = -0.22, up = 0.20} },
    ["reever"] = { distance = 1.1, nozzleOffset = { forward = 0.09, right = -0.20, up = 0.10} },
    ["manchez3"] = { distance = 1.1, nozzleOffset = { forward = -0.04, right = -0.22, up = 0.10} },

    -- truck 2
    ["pounder2"] =  { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.12, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["mule4"] =  { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.35, up = 0.75} },
    ["phantom3"] =  { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["hauler2"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.17, up = 0.02} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["phantom2"] =  { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["mule5"] =  { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.35, up = 0.75} },
    ["stockade"] =  { distance = 3.0, nozzleOffset = { forward = -0.50, right = -1.36, up = 0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["pounder"] =  { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.12, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["phantom"] =  { distance = 1.3, nozzleOffset = { forward = -0.60, right = -0.17, up = 0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["packer"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.17, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["mule"] =  { distance = 1.3, nozzleOffset = { forward = -0.50, right = -0.35, up = 0.75} },
    ["hauler"] =  { distance = 1.3, nozzleOffset = { forward = 0.00, right = -0.17, up = -0.02} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["biff"] =  { distance = 1.3, nozzleOffset = { forward = 0.0, right = 0.11, up = -0.06} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["benson"] =  { distance = 1.3, nozzleOffset = { forward = 0.32, right = 0.40, up = 0.21} , nozzleRotation = { x = 0, y = 0, z = 180} },

    --helicopters
    ["conada2"] = { distance = 3.5, nozzleOffset = { forward = -0.10, right = -0.90, up = 0.20}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["akula"] = { distance = 3.5, nozzleOffset = { forward = -1.50, right = -0.65, up = -0.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["annihilator2"] = { distance = 3.5, nozzleOffset = { forward = -1.10, right = -1.25, up = -1.70}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["annihilator"] = { distance = 3.5, nozzleOffset = { forward = -1.20, right = -1.05, up = -1.70}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["havok"] = { distance = 1.5, nozzleOffset = { forward = -0.10, right = -0.49, up = 0.00}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["hunter"] = { distance = 3.5, nozzleOffset = { forward = -1.50, right = -0.69, up = -0.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["seasparrow"] = { distance = 1.5, nozzleOffset = { forward = -0.10, right = -0.70, up = 0.00}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["seasparrow2"] = { distance = 3.2, nozzleOffset = { forward = -0.10, right = -0.70, up = 0.00}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["supervolito"] = { distance = 2.0, nozzleOffset = { forward = -0.50, right = -0.87, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["supervolito2"] = { distance = 2.0, nozzleOffset = { forward = -0.50, right = -0.87, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["swift"] = { distance = 2.5, nozzleOffset = { forward = -1.10, right = -0.90, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["swift2"] = { distance = 2.5, nozzleOffset = { forward = -1.10, right = -0.90, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["valkyrie"] = { distance = 2.5, nozzleOffset = { forward = 1.60, right = -1.21, up = -1.80}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["valkyrie2"] = { distance = 2.5, nozzleOffset = { forward = 1.60, right = -1.21, up = -1.80}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["volatus"] = { distance = 2.5, nozzleOffset = { forward = -1.10, right = -0.86, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["savage"] = { distance = 3.5, nozzleOffset = { forward = -0.10, right = -1.09, up = -2.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["buzzard2"] = { distance = 2.2, nozzleOffset = { forward = -1.10, right = -0.76, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 10} },
    ["buzzard"] = { distance = 2.5, nozzleOffset = { forward = -1.10, right = -0.76, up = -1.30}, nozzleRotation = { x = 0, y = 0, z = 10} },
    ["cargobob"] = { distance = 4.0, nozzleOffset = { forward = -2.20, right = -1.29, up = -2.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cargobob2"] = { distance = 4.0, nozzleOffset = { forward = -2.20, right = -1.29, up = -2.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cargobob3"] = { distance = 4.0, nozzleOffset = { forward = -2.20, right = -1.29, up = -2.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cargobob4"] = { distance = 4.0, nozzleOffset = { forward = -2.20, right = -1.29, up = -2.30}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["conada"] = { distance = 2.0, nozzleOffset = { forward = -0.09, right = -0.90, up = 0.20}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["frogger"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = -0.92, up = -0.90}, nozzleRotation = { x = 0, y = 0, z = 20} },
    ["frogger2"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = -0.92, up = -0.90}, nozzleRotation = { x = 0, y = 0, z = 20} },
    ["seasparrow3"] = { distance = 1.5, nozzleOffset = { forward = -0.10, right = -0.70, up = 0.00}, nozzleRotation = { x = 0, y = 0, z = 0} },
    ["skylift"] = { distance = 4.0, nozzleOffset = { forward = 4.95, right = 0.00, up = -3.50}, nozzleRotation = { x = 0, y = 0, z = 90} },
    ["maverick"] = { distance = 3.5, nozzleOffset = { forward = 0.00, right = -0.90, up = -1.50}, nozzleRotation = { x = 0, y = 0, z = 20} },

    -- Boats
    ["toro"] = { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.75, up = 0.48 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["toro2"] = { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.75, up = 0.48 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["patrolboat"] = { distance = 1.0, nozzleOffset = { forward = -0.30, right = 0.25, up = 0.20 } , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["longfin"] = { distance = 1.5, nozzleOffset = { forward = 0.90 , right = -1.40, up = 0.68} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["speeder"] = { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.95, up = 0.65 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["speeder2"] = { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.95, up = 0.65 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["tropic"] = { distance = 2.0, nozzleOffset = { forward = 1.00, right = -1.15, up = 0.71} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["tropic2"] = { distance = 2.0, nozzleOffset = { forward = 1.00, right = -1.15, up = 0.71} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["suntrap"] = { distance = 2.0, nozzleOffset = { forward = 0.55, right = -0.95, up = 0.93} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["squalo"] = { distance = 1.5, nozzleOffset = { forward = 0.0, right = -0.95, up = 0.57 } , nozzleRotation = { x = -60, y = 0, z = 90} },
    ["marquis"] = { distance = 1.5, nozzleOffset = { forward = 0.50, right = -1.35, up = 1.36 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["jetmax"] = { distance = 2.0, nozzleOffset = { forward = 0.50, right = -0.90, up = 0.54 } , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["dinghy"] = { distance = 1.0, nozzleOffset = { forward = -0.20, right = -0.69, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dinghy2"] = { distance = 1.0, nozzleOffset = { forward = -0.20, right = -0.69, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dinghy3"] = { distance = 1.0, nozzleOffset = { forward = -0.20, right = -0.69, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dinghy4"] = { distance = 1.0, nozzleOffset = { forward = -0.20, right = -0.69, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dinghy5"] = { distance = 1.0, nozzleOffset = { forward = -0.20, right = -0.69, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },

    -- Jet
    ["seashark"] = { distance = 2.0, nozzleOffset = { forward = 0.89, right = 0.00, up = 0.42 } , nozzleRotation = { x = -60, y = 0, z = 90} },
    ["seashark3"] = { distance = 2.0, nozzleOffset = { forward = 0.89, right = 0.00, up = 0.42 } , nozzleRotation = { x = -60, y = 0, z = 90} },
    ["seashark2"] = { distance = 2.0, nozzleOffset = { forward = 0.89, right = 0.00, up = 0.42 } , nozzleRotation = { x = -60, y = 0, z = 90} },

    -- Submarine
    ["avisa"] = { distance = 2.0, nozzleOffset = { forward = -0.40, right = -1.30, up = 0.14 }  , nozzleRotation = { x = -85, y = 0, z = 90} },
    ["submersible2"] = { distance = 2.5, nozzleOffset = { forward = -0.40, right = -0.70, up = 1.20 }  , nozzleRotation = { x = -90, y = 0, z = 0} },
    ["submersible"] = { distance = 2.5, nozzleOffset = { forward = -0.60, right = -0.85, up = 1.20 }  , nozzleRotation = { x = -90, y = 0, z = 0} },

    -- Big boats
--	["kosatka"] = { distance = 6.0, nozzleOffset = { forward = 0.0, right = -0.15, up = 1.0 } },   ----- BIG SUBMARINE
    ["tug"] = { distance = 2.5, nozzleOffset = { forward = 0.0, right = 0.79, up = 0.20} , nozzleRotation = { x = 0, y = 0, z = 180} },

    -- Plane
    ["streamer216"] = { distance = 1.5, nozzleOffset = { forward = -0.40, right = 1.02, up = 1.10 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["raiju"] = { distance = 3.0, nozzleOffset = { forward = 1.0, right = -0.85, up = -0.25 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["alkonost"] = { distance = 11.0, nozzleOffset = { forward = -2.60, right = -5.30, up = 0.90 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["strikeforce"] = { distance = 3.0, nozzleOffset = { forward = 3.0, right = 1.37, up = 1.60 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["blimp3"] = { distance = 2.0, nozzleOffset = { forward = -0.40, right = 0.41, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["avenger"] = { distance = 2.0, nozzleOffset = { forward = -0.60, right = -0.73, up = 1.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["avenger2"] = { distance = 2.0, nozzleOffset = { forward = -0.60, right = -0.73, up = 1.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["volatol"] = { distance = 2.0, nozzleOffset = { forward = 0.80, right = 0.46, up = 1.85} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["nokota"] = { distance = 2.5, nozzleOffset = { forward = -1.50, right = 1.60, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["seabreeze"] = { distance = 2.5, nozzleOffset = { forward = -0.20, right = -0.10, up = -1.70} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["pyro"] = { distance = 3.0, nozzleOffset = { forward = 2.10, right = 1.56, up = 0.90} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["mogul"] = { distance = 2.0, nozzleOffset = { forward = 0.30, right = -0.68, up = 1.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["howard"] = { distance = 2.5, nozzleOffset = { forward = 1.80, right = 1.25, up = 1.25} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["bombushka"] = { distance = 2.5, nozzleOffset = { forward = 0.50, right = -0.71, up = 1.25} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["molotok"] = { distance = 3.5, nozzleOffset = { forward = 2.00, right = -0.85, up = 0.55} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["microlight"] = { distance = 3.5, nozzleOffset = { forward = -0.02, right = 0.48, up = 0.30} , nozzleRotation = { x = 0, y = 0, z = 45} },
    ["tula"] = { distance = 3.5, nozzleOffset = { forward = 0.70, right = -0.52, up = -0.30} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["rogue"] = { distance = 3.5, nozzleOffset = { forward = 0.10, right = -0.15, up = 0.45} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["starling"] = { distance = 3.5, nozzleOffset = { forward = 0.10, right = -0.08, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["alphaz1"] = { distance = 3.5, nozzleOffset = { forward = -1.00, right = -0.03, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["nimbus"] = { distance = 5.0, nozzleOffset = { forward = 0.00, right = -0.10, up = -0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["luxor2"] = { distance = 5.0, nozzleOffset = { forward = 0.00, right = 0.80, up = -0.30} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["velum2"] = { distance = 5.0, nozzleOffset = { forward = -0.30, right = -0.20, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["hydra"] = { distance = 2.5, nozzleOffset = { forward = -1.80, right = 1.88, up = 1.35} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["blimp2"] = { distance = 2.0, nozzleOffset = { forward = -0.40, right = 0.41, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["dodo"] = { distance = 2.0, nozzleOffset = { forward = -0.15, right = -0.13, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["miljet"] = { distance = 6.0, nozzleOffset = { forward = 2.75, right = -0.47, up = -1.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["vestra"] = { distance = 2.5, nozzleOffset = { forward = 2.50, right = 1.35, up = 1.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cargoplane"] = { distance = 2.5, nozzleOffset = { forward = 1.50, right = 0.27, up = 1.60} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["velum"] = { distance = 5.0, nozzleOffset = { forward = -0.30, right = -0.20, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["titan"] = { distance = 2.5, nozzleOffset = { forward = 0.50, right = -0.46, up = 1.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["shamal"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.10, up = -0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["lazer"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.09, up = -0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["stunt"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.08, up = -0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["luxor"] = { distance = 5.0, nozzleOffset = { forward = 0.00, right = 0.80, up = -0.30} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["jet"] = { distance = 15.0, nozzleOffset = { forward = 1.20, right = 1.20, up = 2.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["duster"] = { distance = 2.5, nozzleOffset = { forward = -0.20, right = -0.15, up = -0.05} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["cuban800"] = { distance = 2.5, nozzleOffset = { forward = 1.00, right = 0.51, up = 0.20} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["blimp"] = { distance = 2.0, nozzleOffset = { forward = -0.40, right = 0.41, up = 0.50 } , nozzleRotation = { x = 0, y = 0, z = 0} },

    -- Service
    ["brickade"] = { distance = 1.3, nozzleOffset = { forward = 0.00, right = 0.16, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["brickade2"] = { distance = 1.3, nozzleOffset = { forward = 0.00, right = 0.16, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },
    ["pbus2"] = { distance = 3.0, nozzleOffset = { forward = -2.38, right = -0.30, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["wastelander"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.05, up = -0.10} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["rallytruck"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = 0.64, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },
--	["metrotrain"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = 0.64, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },  --- metro
--	["freight"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = 0.64, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },		-- train
--	["cablecar"] = { distance = 2.0, nozzleOffset = { forward = 0.00, right = 0.64, up = 0.0} , nozzleRotation = { x = 0, y = 0, z = 180} },	-- cablecar
    ["trash"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.15, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["trash2"] = { distance = 2.5, nozzleOffset = { forward = 0.00, right = -0.15, up = 0.00} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["tourbus"] = { distance = 2.0, nozzleOffset = { forward = -0.50, right = -0.33, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["taxi"] = { distance = 2.0, nozzleOffset = { forward = -0.50, right = -0.20, up = 0.45} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["rentalbus"] = { distance = 2.0, nozzleOffset = { forward = -0.50, right = -0.33, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["coach"] = { distance = 2.0, nozzleOffset = { forward = -0.80, right = -0.29, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["bus"] = { distance = 2.0, nozzleOffset = { forward = -0.80, right = -0.28, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },
    ["airbus"] = { distance = 2.0, nozzleOffset = { forward = -0.80, right = -0.28, up = 0.50} , nozzleRotation = { x = 0, y = 0, z = 0} },

    -- Race
    ["openwheel2"] = { distance = 2.0, nozzleOffset = { forward = 0.0, right = -0.60, up = 0.30} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["openwheel1"] = { distance = 2.0, nozzleOffset = { forward = 0.0, right = -0.60, up = 0.35} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["formula2"] = { distance = 2.0, nozzleOffset = { forward = 0.0, right = -0.50, up = 0.29} , nozzleRotation = { x = -75, y = 0, z = 90} },
    ["formula"] = { distance = 2.0, nozzleOffset = { forward = 0.0, right = -0.50, up = 0.29} , nozzleRotation = { x = -75, y = 0, z = 90} },
}