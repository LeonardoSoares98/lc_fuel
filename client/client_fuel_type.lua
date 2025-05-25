local function isInList(modelName, list)
    for _, name in ipairs(list) do
        if name == modelName then
            return true
        end
    end
    return false
end

local function getFuelType(vehicle)
    if not DoesEntityExist(vehicle) then return "Unkown" end
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()

    if isInList(model, Config.Electric.vehiclesList) then
        return Utils.translate("electric")
    elseif isInList(model, Config.DieselVehicles) then
        return Utils.translate("diesel")
    else
        return Utils.translate("gasoline")
    end
end


RegisterCommand(Config.FuelTypeCommand, function()
    local vehicle =  GetVehiclePedIsIn(PlayerPedId(), false)
    local fuelType = getFuelType(vehicle)
    exports['lc_utils']:notify("info", Utils.translate("fuel_type") .. " " .. fuelType)
end, false)

