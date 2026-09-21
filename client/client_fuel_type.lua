RegisterCommand(Config.FuelTypeCommand, function()
    local vehicle =  GetVehiclePedIsIn(PlayerPedId(), false)
    if not DoesEntityExist(vehicle) then
        exports['lc_utils']:notify("error", Utils.translate("vehicle_not_found"))
        return
    end

    local fuelType = getVehicleFuelTypeFromServer(vehicle)
    exports['lc_utils']:notify("info", Utils.translate("fuel_types.type_title"):format(Utils.translate("fuel_types."..fuelType)))
end, false)

if Config.EnableSetFuelCommand and Config.SetFuelCommand and Config.SetFuelCommand ~= "" then
    TriggerEvent("chat:addSuggestion", "/"..Config.SetFuelCommand, "Set vehicle fuel level (0-100)", {
        { name = "amount", help = "0-100" }
    })

    RegisterCommand(Config.SetFuelCommand, function(_, args)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if not DoesEntityExist(vehicle) then
            exports['lc_utils']:notify("error", Utils.translate("vehicle_not_found"))
            return
        end

        local value = tonumber(args[1])
        if not value then
            exports['lc_utils']:notify("error", "Usage: /"..Config.SetFuelCommand.." 0-100")
            return
        end

        value = math.max(0, math.min(value, 100))
        SetFuel(vehicle, value)
        exports['lc_utils']:notify("success", "Fuel set to "..value.."%")
    end, false)
end
