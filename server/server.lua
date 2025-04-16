
-----------------------------------------------------------------------------------------------------------------------------------------
-- Versioning
-----------------------------------------------------------------------------------------------------------------------------------------

version = ''
subversion = ''
api_response = {}
local utils_required_version = '1.2.1'
local utils_outdated = false

function checkVersion()
    CreateThread(function()
        local connected = false
        local attempts = 0
        while not connected and attempts < 3 do
            attempts = attempts + 1

            PerformHttpRequest("https://raw.githubusercontent.com/LeonardoSoares98/lc_fuel/main/version", function(errorCode, resultData)
                if errorCode == 200 and resultData then
                    connected = true
                    local latest_version = Utils.Math.trim(resultData)

                    api_response.latest_version = latest_version
                    if Utils.Math.checkIfCurrentVersionisOutdated(latest_version, version) then
                        api_response.has_update = true
                        print("^4["..GetCurrentResourceName().."] An update is available, download it in https://github.com/LeonardoSoares98/lc_fuel/releases/latest/download/lc_fuel.zip^7 ^3[v"..api_response.latest_version.."]^7")
                    else
                        api_response.has_update = false
                    end
                end
            end, "GET", "", {})

            Wait(10000)
        end
    end)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Script global variables
-----------------------------------------------------------------------------------------------------------------------------------------

Utils = Utils or exports['lc_utils']:GetUtils()
local cooldown = {}
local playerVehiclesFuelType = {}
local fuelPurchased = {}

-----------------------------------------------------------------------------------------------------------------------------------------
-- Script functions
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterServerEvent("lc_fuel:serverOpenUI")
AddEventHandler("lc_fuel:serverOpenUI",function(isElectric, pumpModel, vehicleFuel, vehicleTankSize, vehiclePlate)
    local source = source
    Wrapper(source,function(user_id)
        local gasStationId = getCurrentGasStationId(source)
        serverOpenUI(source, isElectric, pumpModel, gasStationId, vehicleFuel, vehicleTankSize, vehiclePlate)
    end)
end)

RegisterServerEvent("lc_fuel:confirmRefuel")
AddEventHandler("lc_fuel:confirmRefuel",function(data)
    local source = source
    Wrapper(source,function(user_id)
        if not data or data.fuelAmount <= 0 or not isFuelTypeValid(data.selectedFuelType) or not isPaymentMethodValid(data.paymentMethod) then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('invalid_value'))
            return
        end

        local gasStationId = getCurrentGasStationId(source)
        local stationData = getStationData(gasStationId)
        local pricePerLiter = stationData.pricePerLiter[data.selectedFuelType]
        local initialPrice = pricePerLiter * data.fuelAmount

        local discount = getPlayerDiscountAmount(source)
        local finalPrice = initialPrice * (1 - (discount / 100))
        if Utils.Framework.getPlayerAccountMoney(source, Config.Accounts[data.paymentMethod]) < finalPrice then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('not_enough_money'):format(Utils.numberFormat(finalPrice)))
            return
        end

        if not removeStockFromStation(gasStationId, finalPrice, data.fuelAmount, data.selectedFuelType, false) then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('not_enough_stock'))
            return
        end

        Utils.Framework.tryRemoveAccountMoney(source, finalPrice, Config.Accounts[data.paymentMethod])

        fuelPurchased[source] = {
            finalPrice = finalPrice,
            account = Config.Accounts[data.paymentMethod],
            selectedFuelType = data.selectedFuelType,
            fuelAmount = data.fuelAmount,
            pricePerLiter = pricePerLiter,
        }

        TriggerClientEvent("lc_fuel:getPumpNozzle", source, data.fuelAmount, data.selectedFuelType)
        TriggerClientEvent("lc_fuel:Notify", source, "success", Utils.translate('refuel_paid'):format(Utils.numberFormat(finalPrice)))
    end)
end)


RegisterServerEvent("lc_fuel:returnNozzle")
AddEventHandler("lc_fuel:returnNozzle",function(remainingFuel, isElectric)
    local source = source
    Wrapper(source,function(user_id)

        if not Config.ReturnNozzleRefund then
            return
        end

        if not fuelPurchased[source] then
            return
        end

        if remainingFuel < 1 then
            fuelPurchased[source] = nil
            return
        end

        local discount = getPlayerDiscountAmount(source)
        local amountToReturn = math.floor(remainingFuel * (fuelPurchased[source].pricePerLiter * (1 - (discount / 100))))

        if amountToReturn > fuelPurchased[source].finalPrice or remainingFuel > fuelPurchased[source].fuelAmount then
            print("User "..user_id.." initially purchased "..fuelPurchased[source].fuelAmount.."L of fuel but now is returning "..remainingFuel.."L. Is this user trying to glitch something?")
            print("User coords: "..GetEntityCoords(GetPlayerPed(source)))
            fuelPurchased[source] = nil
            return
        end

        if isElectric then
            TriggerClientEvent("lc_fuel:Notify", source, "success", Utils.translate('returned_charge'):format(Utils.Math.round(remainingFuel, 1), amountToReturn))
        else
            TriggerClientEvent("lc_fuel:Notify", source, "success", Utils.translate('returned_fuel'):format(Utils.Math.round(remainingFuel, 1), amountToReturn))
        end
        Utils.Framework.giveAccountMoney(source, amountToReturn, fuelPurchased[source].account)

        fuelPurchased[source] = nil
    end)
end)

RegisterServerEvent("lc_fuel:confirmJerryCanPurchase")
AddEventHandler("lc_fuel:confirmJerryCanPurchase",function(data)
    if not Config.JerryCan.enabled then return end
    local source = source
    Wrapper(source,function(user_id)
        if not isPaymentMethodValid(data.paymentMethod) then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('invalid_value'))
            return
        end

        local gasStationId = getCurrentGasStationId(source)
        local stationData = getStationData(gasStationId)
        local fuelType = nil
        -- Check which type has enough stock
        if stationData.stationStock.regular >= Config.JerryCan.requiredStock then
            fuelType = "regular"
        elseif stationData.stationStock.plus >= Config.JerryCan.requiredStock then
            fuelType = "plus"
        elseif stationData.stationStock.premium >= Config.JerryCan.requiredStock then
            fuelType = "premium"
        elseif stationData.stationStock.diesel >= Config.JerryCan.requiredStock then
            fuelType = "diesel"
        end

        if fuelType == nil then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('not_enough_stock'))
            return
        end

        if Utils.Framework.getPlayerAccountMoney(source, Config.Accounts[data.paymentMethod]) < Config.JerryCan.price then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('not_enough_money'):format(Config.JerryCan.price))
            return
        end

        if not removeStockFromStation(gasStationId, Config.JerryCan.price, Config.JerryCan.requiredStock, fuelType, true) then
            TriggerClientEvent("lc_fuel:Notify", source, "error", Utils.translate('not_enough_stock'))
            return
        end
        Utils.Framework.tryRemoveAccountMoney(source, Config.JerryCan.price, Config.Accounts[data.paymentMethod])

        -- Gives the jerry can to the player
        if Config.JerryCan.giveAsWeapon then
            Utils.Framework.givePlayerWeapon(source, Config.JerryCan.item, 1, Config.JerryCan.metadata)
        else
            Utils.Framework.givePlayerItem(source, Config.JerryCan.item, 1, Config.JerryCan.metadata)
        end

        TriggerClientEvent("lc_fuel:Notify", source, "success", Utils.translate('jerry_can_paid'):format(Config.JerryCan.price))
        TriggerClientEvent("lc_fuel:closeUI", source, data.fuelAmount, data.selectedFuelType)
    end)
end)

function serverOpenUI(source, isElectric, pumpModel, gasStationId, vehicleFuel, vehicleTankSize, vehiclePlate)
    local stationData = getStationData(gasStationId)
    local discount = getPlayerDiscountAmount(source)

    local data = {
        pricePerLiter = stationData.pricePerLiter,
        stationStock = stationData.stationStock,
        currentFuelType = getVehicleFuelType(vehiclePlate),
        vehicleFuel = vehicleFuel or 0,
        vehicleTankSize = vehicleTankSize or 100,
        cashBalance = Utils.Framework.getPlayerAccountMoney(source, Config.Accounts.account1),
        bankBalance = Utils.Framework.getPlayerAccountMoney(source, Config.Accounts.account2),
        jerryCan = Config.JerryCan,
        isElectric = isElectric,
        electric = Config.Electric,
        pumpModel = pumpModel,
    }

    -- Apply the discount to each fuel type price based on player job
    for fuelType, price in pairs(stationData.pricePerLiter) do
        data.pricePerLiter[fuelType] = price * (1 - (discount / 100))
    end

    TriggerClientEvent("lc_fuel:clientOpenUI", source, data)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Gas Station stock functions
-----------------------------------------------------------------------------------------------------------------------------------------

function getCurrentGasStationId(source)
    if not Config.PlayerOwnedGasStations.enabled then return nil end
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for k,v in pairs(Config.PlayerOwnedGasStations.gasStations) do
        if #(v.vector - playerCoords) <= v.radius then
            return k
        end
    end
    return nil
end

function getStationData(gasStationId)
    local stationData = getStationDataFromConfig()
    if not gasStationId then
        return stationData
    end

    local sql = "SELECT price, stock, price_plus, stock_plus, price_premium, stock_premium, price_diesel, stock_diesel, price_electricfast, stock_electricfast, price_electricnormal, stock_electricnormal FROM gas_station_business WHERE gas_station_id = @gas_station_id";
    local query = Utils.Database.fetchAll(sql, {['@gas_station_id'] = gasStationId})[1];

    if not query then
        return stationData
    end

    local sql = "UPDATE `gas_station_business` SET total_visits = total_visits + 1 WHERE gas_station_id = @gas_station_id";
    Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId});

    stationData = {
        pricePerLiter = {
            regular = query.price/100,
            plus = query.price_plus/100,
            premium = query.price_premium/100,
            diesel = query.price_diesel/100,
            electricfast = query.price_electricfast/100,
            electricnormal = query.price_electricnormal/100,
        },
        stationStock = {
            regular = query.stock,
            plus = query.stock_plus,
            premium = query.stock_premium,
            diesel = query.stock_diesel,
            electricfast = query.stock_electricfast == 1 and 100 or 0,
            electricnormal = query.stock_electricnormal == 1 and 100 or 0,
        }
    }

    return stationData
end

function removeStockFromStation(gasStationId, pricePaid, fuelAmount, fuelType, isJerryCan)
    if not isFuelTypeValid(fuelType) then
        print("Invalid fuel type: "..(fuelType or "nil"))
        return false
    end

    -- If not owned
    local stationData = getStationDataFromConfig()
    if not gasStationId then
        if stationData.stationStock[fuelType] >= fuelAmount then
            -- If set in config to unowed gas stations have stock
            return true
        else
            return false
        end
    end

    local column = "stock_"..fuelType
    if fuelType == "regular" then
        column = "stock"
    end

    local sql = "SELECT "..column.." as stock FROM gas_station_business WHERE gas_station_id = @gas_station_id";
    local query = Utils.Database.fetchAll(sql, {['@gas_station_id'] = gasStationId})[1];

    if not query then
        if stationData.stationStock[fuelType] >= fuelAmount then
            -- If set in config to unowed gas stations have stock
            return true
        else
            return false
        end
    end

    if isFuelTypeElectric(fuelType) then
        if query.stock < 1 then
            return false
        end

        local sql = "UPDATE `gas_station_business` SET customers = customers + 1, money = money + @price, total_money_earned = total_money_earned + @price WHERE gas_station_id = @gas_station_id";
        Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId, ['@price'] = pricePaid, ['@amount'] = fuelAmount});

        if isJerryCan then
            print("Jerry can in electric charger???")
            return false
        else
            local sql = "INSERT INTO `gas_station_balance` (gas_station_id,income,title,amount,date) VALUES (@gas_station_id,@income,@title,@amount,@date)";
            Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId, ['@income'] = 0, ['@title'] = Utils.translate('owned_gas_stations.balance_electric'):format(fuelAmount), ['@amount'] = pricePaid, ['@date'] = os.time()});
        end
    else
        if query.stock < fuelAmount then
            return false
        end

        local sql = "UPDATE `gas_station_business` SET "..column.." = @stock, customers = customers + 1, money = money + @price, total_money_earned = total_money_earned + @price, gas_sold = gas_sold + @amount WHERE gas_station_id = @gas_station_id";
        Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId, ['@stock'] = (query.stock - fuelAmount), ['@price'] = pricePaid, ['@amount'] = fuelAmount});

        if isJerryCan then
            local sql = "INSERT INTO `gas_station_balance` (gas_station_id,income,title,amount,date) VALUES (@gas_station_id,@income,@title,@amount,@date)";
            Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId, ['@income'] = 0, ['@title'] = Utils.translate('owned_gas_stations.balance_jerry_can'):format(fuelAmount), ['@amount'] = pricePaid, ['@date'] = os.time()});
        else
            local sql = "INSERT INTO `gas_station_balance` (gas_station_id,income,title,amount,date) VALUES (@gas_station_id,@income,@title,@amount,@date)";
            Utils.Database.execute(sql, {['@gas_station_id'] = gasStationId, ['@income'] = 0, ['@title'] = Utils.translate('owned_gas_stations.balance_fuel'):format(fuelAmount), ['@amount'] = pricePaid, ['@date'] = os.time()});
        end
    end
    return true
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Utils functions
-----------------------------------------------------------------------------------------------------------------------------------------

function getStationDataFromConfig()
    return {
        pricePerLiter = {
            regular = Config.DefaultValues.fuelPrice.regular,
            plus = Config.DefaultValues.fuelPrice.plus,
            premium = Config.DefaultValues.fuelPrice.premium,
            diesel = Config.DefaultValues.fuelPrice.diesel,
            electricfast = Config.Electric.chargeTypes.fast.price,
            electricnormal = Config.Electric.chargeTypes.normal.price,
        },
        stationStock = {
            regular = Config.DefaultValues.fuelStock.regular and 1000 or 0,
            plus = Config.DefaultValues.fuelStock.plus and 1000 or 0,
            premium = Config.DefaultValues.fuelStock.premium and 1000 or 0,
            diesel = Config.DefaultValues.fuelStock.diesel and 1000 or 0,
            electricfast = Config.Electric.chargeTypes.fast.stock and 1000 or 0,
            electricnormal = Config.Electric.chargeTypes.normal.stock and 1000 or 0,
        }
    }
end

function isFuelTypeValid(fuelType)
    return Utils.Table.contains({"regular", "plus", "premium", "diesel", "electricfast", "electricnormal"}, fuelType)
end

function isFuelTypeElectric(fuelType)
    return Utils.Table.contains({"electricnormal", "electricfast"}, fuelType)
end

function isPaymentMethodValid(paymentMethod)
    return Utils.Table.contains({"account1", "account2"}, paymentMethod) -- These are not really the account, but the index to the Config.Accounts
end

function getPlayerDiscountAmount(source)
    local job, onDuty = Utils.Framework.getPlayerJob(source)
    if onDuty and job and Config.JobDiscounts[job] then
        return Config.JobDiscounts[job]
    end
    return 0
end

Utils.Callback.RegisterServerCallback('lc_fuel:getVehicleFuelType', function(source, cb, plate)
    cb(getVehicleFuelType(plate))
end)

RegisterServerEvent("lc_fuel:setVehicleFuelType")
AddEventHandler("lc_fuel:setVehicleFuelType",function(plate, fuelType)
    setVehicleFuelType(plate, fuelType)
end)

function getVehicleFuelType(plate)
    return playerVehiclesFuelType[plate] or "default"
end

function setVehicleFuelType(plate, fuelType)
    if not isFuelTypeValid(fuelType) then
        fuelType = "regular"
        print("Invalid fuel type ("..fuelType..") set to vehicle ("..plate..")")
    end

    playerVehiclesFuelType[plate] = fuelType
    local sql = [[
        INSERT INTO `player_vehicles_fuel_type` (plate, fuelType)
        VALUES (@plate, @fuelType)
        ON DUPLICATE KEY UPDATE fuelType = @fuelType
    ]];
    Utils.Database.execute(sql, {['@plate'] = plate, ['@fuelType'] = fuelType})
end

function cacheplayerVehiclesFuelTypeType()
    local sql = "SELECT * FROM player_vehicles_fuel_type";
    local queryData = Utils.Database.fetchAll(sql, {});
    for _, value in pairs(queryData) do
        playerVehiclesFuelType[value.plate] = value.fuelType
    end
    print("^2[lc_fuel] Fuel types successfully fetched from database^7")
end

function Wrapper(source,cb)
    if utils_outdated then
        TriggerClientEvent("lc_fuel:Notify",source,"error","The script requires 'lc_utils' in version "..utils_required_version..", but you currently have version "..Utils.Version..". Please update your 'lc_utils' script to the latest version: https://github.com/LeonardoSoares98/lc_utils/releases/latest/download/lc_utils.zip")
        return
    end

    if cooldown[source] == nil then
        cooldown[source] = true
        local user_id = Utils.Framework.getPlayerId(source)
        if user_id then
            cb(user_id)
        else
            print("User not found: "..source)
        end
        SetTimeout(100,function()
            cooldown[source] = nil
        end)
    end
end


Citizen.CreateThread(function()
    Wait(1000)

    -- Load version number from file
    local versionFile = LoadResourceFile("lc_fuel", "version")
    if versionFile then
        version = Utils.Math.trim(versionFile)
        print("^2[lc_fuel] Loaded! Support discord: https://discord.gg/U5YDgbh ^3[v"..version..subversion.."]^7")
    else
        error("^1[lc_fuel] Warning: Could not load the version file.^7")
    end

    checkIfFrameworkWasLoaded()
    checkScriptName()

    -- Startup queries
    runCreateTableQueries()
    cacheplayerVehiclesFuelTypeType()

    -- Config checker
    assert(Config.FuelConsumptionPerClass, "^3You have errors in your config file, consider fixing it or redownload the original config.^7")

    -- Check lc_utils dependency
    assert(GetResourceState('lc_utils') == 'started', "^3The '^1lc_utils^3' file is missing. Please refer to the documentation for installation instructions: ^7https://docs.lixeirocharmoso.com/fuel/installation^7")

    if Utils.Math.checkIfCurrentVersionisOutdated(utils_required_version, Utils.Version) then
        utils_outdated = true
        error("^3The script requires 'lc_utils' in version ^1"..utils_required_version.."^3, but you currently have version ^1"..Utils.Version.."^3. Please update your 'lc_utils' script to the latest version: https://github.com/LeonardoSoares98/lc_utils/releases/latest/download/lc_utils.zip^7")
    end

    -- Load langs
    Utils.loadLanguageFile(Lang)

    -- Config validator
    local configs_to_validate = {
        { config_path = {"Blips", "onlyShowNearestBlip"}, default_value = false },
        { config_path = {"ReturnNozzleRefund"}, default_value = true },
    }
    Config = Utils.validateConfig(Config, configs_to_validate)

    Wait(1000)

    checkVersion()
end)

function checkIfFrameworkWasLoaded()
    assert(Utils.Framework.getPlayerId, "^3The framework wasn't loaded in the '^1lc_utils^3' resource. Please check if the '^1Config.framework^3' is correctly set to your framework, and make sure there are no errors in your file. For more information, refer to the documentation at '^7https://docs.lixeirocharmoso.com/^3'.^7")
end

function checkScriptName()
    assert(GetCurrentResourceName() == "lc_fuel", "^3The script name does not match the expected resource name. Please ensure that the current resource name is set to '^1lc_fuel^7'.")
end

function runCreateTableQueries()
    Utils.Database.execute([[
        CREATE TABLE IF NOT EXISTS `player_vehicles_fuel_type` (
            `plate` VARCHAR(20) NOT NULL COLLATE 'utf8_general_ci',
            `fuelType` VARCHAR(20) NOT NULL COLLATE 'utf8_general_ci',
            PRIMARY KEY (`plate`) USING BTREE
        )
        COLLATE='utf8_general_ci'
        ENGINE=InnoDB
        ;
    ]])
end
