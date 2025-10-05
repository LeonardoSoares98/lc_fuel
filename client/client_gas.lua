local customGasPumps = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- Threads
-----------------------------------------------------------------------------------------------------------------------------------------

-- Thread to detect near fuel pumps
function createGasMarkersThread()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local pump, pumpModel = GetClosestPump(playerCoords, false)

            while pump and pump > 0 and #(playerCoords - GetEntityCoords(pump)) < 2.0 do
                playerCoords = GetEntityCoords(ped)
                if not mainUiOpen and not DoesEntityExist(fuelNozzle) then
                    Utils.Markers.showHelpNotification(cachedTranslations.open_refuel, true)
                    if IsControlJustPressed(0,38) then
                        clientOpenUI(pump, pumpModel, false)
                    end
                end
                Wait(2)
            end
            Wait(1000)
        end
    end)
end

function createGasTargetsThread()
    local pumpModels = {}
    for _, v in pairs(Config.GasPumpProps) do
        table.insert(pumpModels, v.prop)
    end
    Utils.Target.createTargetForModel(pumpModels,openFuelUICallback,Utils.translate('target.open_refuel'),"fas fa-gas-pump","#a42100",nil,nil,canOpenPumpUiTargetCallback)

    Utils.Target.createTargetForModel(pumpModels,returnNozzle,Utils.translate('target.return_nozzle'),"fas fa-gas-pump","#a42100",nil,nil,canReturnNozzleTargetCallback)
end

function openFuelUICallback()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local pump, pumpModel = GetClosestPump(playerCoords, false)
    if pump then
        clientOpenUI(pump, pumpModel, false)
    else
        exports['lc_utils']:notify("error", Utils.translate("pump_not_found"))
    end
end

function createCustomPumpModelsThread()
    for _, pumpConfig in pairs(Config.CustomGasPumpLocations) do
        RequestModel(pumpConfig.prop)

        while not HasModelLoaded(pumpConfig.prop) do
            Wait(50)
        end

        local heading = pumpConfig.location.w + 180.0
        local gasPump = CreateObject(pumpConfig.prop, pumpConfig.location.x, pumpConfig.location.y, pumpConfig.location.z, false, true, true)
        SetEntityHeading(gasPump, heading)
        FreezeEntityPosition(gasPump, true)
        table.insert(customGasPumps, gasPump)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    deleteAllCustomGasPumps()
end)

function deleteAllCustomGasPumps()
    for k, v in ipairs(customGasPumps) do
        DeleteEntity(v)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Jerry Cans
-----------------------------------------------------------------------------------------------------------------------------------------

-- Thread to handle the fuel consumption
function createJerryCanThread()
    CreateThread(function()
        while true do
            Wait(1000)
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) and GetSelectedPedWeapon(ped) == JERRY_CAN_HASH then
                refuelLoop(true)
            end
        end
    end)
end

-- Code to save jerry can ammo in any inventory
local currentWeaponData
function updateWeaponAmmo(ammo)
    ammo = math.floor(ammo) -- This is needed or some inventories will break

    if currentWeaponData and currentWeaponData.info and currentWeaponData.info.ammo then
        currentWeaponData.info.ammo = ammo
    end

    TriggerServerEvent('ox_inventory:updateWeapon', "ammo", ammo)
    TriggerServerEvent("weapons:server:UpdateWeaponAmmo", currentWeaponData, ammo)
    TriggerServerEvent("qb-weapons:server:UpdateWeaponAmmo", currentWeaponData, ammo)

    if Config.Debug then print("updateWeaponAmmo:ammo",ammo) end
    if Config.Debug then Utils.Debug.printTable("updateWeaponAmmo:currentWeaponData",currentWeaponData) end

    local ped = PlayerPedId()
    SetPedAmmo(ped, JERRY_CAN_HASH, ammo)
end

AddEventHandler('weapons:client:SetCurrentWeapon', function(data, bool)
    if bool ~= false then
        currentWeaponData = data
    else
        currentWeaponData = {}
    end
end)

AddEventHandler('qb-weapons:client:SetCurrentWeapon', function(data, bool)
    if bool ~= false then
        currentWeaponData = data
    else
        currentWeaponData = {}
    end
end)

AddEventHandler('ox_inventory:currentWeapon', function(weapon)
    if weapon then
        if weapon.metadata then
            weapon.info = weapon.metadata
        end
        currentWeaponData = weapon
    else
        currentWeaponData = {}
    end
end)

-- Get jerry can ammo by metadata
function getJerryCanAmmo()
    if currentWeaponData and currentWeaponData.info and currentWeaponData.info.ammo then
        if Config.Debug then print("getJerryCanAmmo:currentWeaponData.info.ammo", currentWeaponData.info.ammo) end
        return currentWeaponData.info.ammo
    end
    local ped = PlayerPedId()
    if Config.Debug then print("getJerryCanAmmo:GetAmmoInPedWeapon", GetAmmoInPedWeapon(ped, JERRY_CAN_HASH)) end
    return GetAmmoInPedWeapon(ped, JERRY_CAN_HASH)
end
