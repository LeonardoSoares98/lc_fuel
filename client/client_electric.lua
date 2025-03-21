-- Do not load anything here if electric is disabled
if not Config.Electric.enabled then
	return
end

local electricChargers = {}

-----------------------------------------------------------------------------------------------------------------------------------------
-- Threads
-----------------------------------------------------------------------------------------------------------------------------------------

-- Create sphere zones for each station, hooking up onEnter/onExit
function createElectricZones()
    local stations = groupChargersByStation()

    for _, station in pairs(stations) do
        Utils.Zones.createZone({
            coords = station.center,
            radius = 50.0,
            onEnter = function()
                for _, charger in pairs(station.chargers) do
                    loadElectricCharger(charger)
                end
            end,
            onExit = function()
                for _, charger in pairs(station.chargers) do
                    unloadElectricCharger(charger)
                end
            end
        })
    end
end

-- Thread to detect near electric chargers
function createElectricMarkersThread()
	CreateThread(function()
		while true do
			local ped = PlayerPedId()
			local playerCoords = GetEntityCoords(ped)
			local pump, pumpModel = GetClosestPump(playerCoords, true)

			while pump and pump > 0 and #(playerCoords - GetEntityCoords(pump)) < 2.0 do
				playerCoords = GetEntityCoords(ped)
				if not mainUiOpen and not DoesEntityExist(fuelNozzle) then
					Utils.Markers.showHelpNotification(cachedTranslations.open_recharge, true)
					if IsControlJustPressed(0,38) then
						clientOpenUI(pump, pumpModel, true)
					end
				end
				Wait(2)
			end
			Wait(1000)
		end
	end)
end

function createElectricTargetsThread()
	local pumpModels = {}  -- This will be the final list without duplicates
	local seenModels = {}  -- This acts as a set to track unique values

	for _, chargerData in pairs(Config.Electric.chargersLocation) do
		local model = chargerData.prop
		if not seenModels[model] then
			seenModels[model] = true  -- Mark model as seen
			table.insert(pumpModels, model)  -- Insert only if it's not a duplicate
		end
	end

	-- Pass unique models to the target creation function
	Utils.Target.createTargetForModel(pumpModels, openElectricUICallback, cachedTranslations.open_recharge_target, "fas fa-plug", "#00a413")
end

function openElectricUICallback()
	local ped = PlayerPedId()
	local playerCoords = GetEntityCoords(ped)
	local pump, pumpModel = GetClosestPump(playerCoords, true)
	if pump then
		clientOpenUI(pump, pumpModel, true)
	else
		exports['lc_utils']:notify("error", Utils.translate("pump_not_found"))
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Utils
-----------------------------------------------------------------------------------------------------------------------------------------

function loadElectricCharger(chargerData)
    if not electricChargers[chargerData.location] then
        RequestModel(chargerData.prop)
        while not HasModelLoaded(chargerData.prop) do
            Wait(10)
        end

        local heading = chargerData.location.w + 180.0
        local electricCharger = CreateObject(chargerData.prop, chargerData.location.x, chargerData.location.y, chargerData.location.z, false, true, true)
        SetEntityHeading(electricCharger, heading)
        FreezeEntityPosition(electricCharger, true)

        electricChargers[chargerData.location] = electricCharger
    end
end

function unloadElectricCharger(chargerData)
    local charger = electricChargers[chargerData.location]
    if charger and DoesEntityExist(charger) then
        DeleteEntity(charger)
        electricChargers[chargerData.location] = nil
    end
end

-- Utility to group chargers by their station
function groupChargersByStation()
    local stations = {}
    for _, charger in pairs(Config.Electric.chargersLocation) do
        local assigned = false
        for _, station in pairs(stations) do
            local dist = #(station.center - vector3(charger.location.x, charger.location.y, charger.location.z))
            if dist < 20.0 then
                table.insert(station.chargers, charger)
                station.center = (station.center + vector3(charger.location.x, charger.location.y, charger.location.z)) / 2
                assigned = true
                break
            end
        end
        if not assigned then
            table.insert(stations, {
                center = vector3(charger.location.x, charger.location.y, charger.location.z),
                chargers = { charger }
            })
        end
    end
    return stations
end

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then return end

	deleteAllElectricChargers()
end)

function deleteAllElectricChargers()
    for _, charger in pairs(electricChargers) do
        if DoesEntityExist(charger) then
            DeleteEntity(charger)
        end
    end
    electricChargers = {}
end