RegisterCommand(Config.FuelTypeCommand, function()
    local vehicle =  GetVehiclePedIsIn(PlayerPedId(), false)
    if not DoesEntityExist(vehicle) then
        exports['lc_utils']:notify("error", Utils.translate("vehicle_not_found"))
        return
    end

    local fuelType = getVehicleFuelTypeFromServer(vehicle)
    exports['lc_utils']:notify("info", Utils.translate("fuel_types.type_title"):format(Utils.translate("fuel_types."..fuelType)))
end, false)