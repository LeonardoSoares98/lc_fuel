local JERRY_CAN_HASH = 883325847
local customGasPumps = {}

distanceToCap, distanceToPump = math.maxinteger, math.maxinteger
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
	Utils.Target.createTargetForModel(pumpModels,openFuelUICallback,cachedTranslations.open_refuel_target,"fas fa-gas-pump","#a42100")
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
	TriggerServerEvent('ox_inventory:updateWeapon', "ammo", ammo)
	TriggerServerEvent("weapons:server:UpdateWeaponAmmo", currentWeaponData, ammo)
	TriggerServerEvent("qb-weapons:server:UpdateWeaponAmmo", currentWeaponData, ammo)

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

-- Get jerry can ammo by metadata
function getJerryCanAmmo()
	if currentWeaponData and currentWeaponData.info and currentWeaponData.info.ammo then
		return currentWeaponData.info.ammo
	end
	local ped = PlayerPedId()
	return GetAmmoInPedWeapon(ped, JERRY_CAN_HASH)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Refuelling
-----------------------------------------------------------------------------------------------------------------------------------------

local isRefuelling = false
RegisterNetEvent('lc_fuel:getPumpNozzle')
AddEventHandler('lc_fuel:getPumpNozzle', function(fuelAmountPurchased, fuelTypePurchased)
	closeUI()
	if DoesEntityExist(fuelNozzle) then return end
	if not currentPump then return end
	local ped = PlayerPedId()
	local pumpCoords = GetEntityCoords(currentPump)

	Utils.Animations.loadAnimDict("anim@am_hold_up@male")
	TaskPlayAnim(ped, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, false, false, false)
	Wait(300)
	StopAnimTask(ped, "anim@am_hold_up@male", "shoplift_high", 1.0)

	local nozzle_prop_label = Config.NozzleProps.gas
	-- Change the fuel tick if its electric charging
	if fuelTypePurchased == "electricfast" or fuelTypePurchased == "electricnormal" then
		nozzle_prop_label = Config.NozzleProps.electric
	end

	RequestModel(nozzle_prop_label)

	while not HasModelLoaded(nozzle_prop_label) do
		Wait(50)
	end

	fuelNozzle = CreateObject(joaat(nozzle_prop_label), 1.0, 1.0, 1.0, true, true, false)

	attachNozzleToPed()
	if Config.EnablePumpRope then
		fuelRope = CreateRopeToPump(pumpCoords)
	end

	local distanceToFindPump = 10
	local ropeLength = Config.DefaultRopeLength
	if fuelTypePurchased == "electricfast" or fuelTypePurchased == "electricnormal" then
		for _, pumpConfig in pairs(Config.Electric.chargersLocation) do
			local distance = #(vector3(pumpConfig.location.x, pumpConfig.location.y, pumpConfig.location.z) - pumpCoords)
			if distance < distanceToFindPump then
				ropeLength = pumpConfig.ropeLength
				break
			end
		end
	else
		for _, pumpConfig in pairs(Config.CustomGasPumpLocations) do
			local distance = #(vector3(pumpConfig.location.x, pumpConfig.location.y, pumpConfig.location.z) - pumpCoords)
			if distance < distanceToFindPump then
				ropeLength = pumpConfig.ropeLength
				break
			end
		end
	end

	-- Thread to handle fuel nozzle
	CreateThread(function()
		while DoesEntityExist(fuelNozzle) do
			local waitTime = 500
			local nozzleCoords = GetEntityCoords(fuelNozzle)
			distanceToPump = #(pumpCoords - nozzleCoords)
			if distanceToPump > ropeLength then
				exports['lc_utils']:notify("error", Utils.translate("too_far_away"))
				deleteRopeAndNozzleProp()
			end
			if distanceToPump > (ropeLength * 0.7) then
				Utils.Markers.showHelpNotification(Utils.translate("too_far_away"), true)
			end
			-- Check if ped entered a vehicle
			if IsPedSittingInAnyVehicle(ped) then
				-- Gives him 2 seconds to leave before clearing the nozzle
				SetTimeout(2000,function()
					if IsPedSittingInAnyVehicle(ped) and DoesEntityExist(fuelNozzle) then
						exports['lc_utils']:notify("error", Utils.translate("too_far_away"))
						deleteRopeAndNozzleProp()
					end
				end)
			end
			if distanceToPump < 1.5 then
				waitTime = 2
				Utils.Markers.showHelpNotification(cachedTranslations.return_nozzle, true)
				if IsControlJustPressed(0,38) then
					-- See which one the player is nearer. The fuel cap or fuel pump
					if distanceToPump < distanceToCap then
						Wait(100)
						-- Avoid player press E to return nozzle and press E to refuel in same tick, so it gives preference to refuel
						if not isRefuelling then
							Utils.Animations.loadAnimDict("anim@am_hold_up@male")
							TaskPlayAnim(ped, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, false, false, false)
							Wait(300)
							StopAnimTask(ped, "anim@am_hold_up@male", "shoplift_high", 1.0)
							deleteRopeAndNozzleProp()
						end
					end
				end
			end
			Wait(waitTime)
		end
		-- Not near the pump anymore
		distanceToPump = math.maxinteger
	end)

	-- Thread to refuel the vehicle
	CreateThread(function()
		refuelLoop(false, fuelAmountPurchased, fuelTypePurchased, fuelNozzle)
		-- Not near the fuel cap anymore
		distanceToCap = math.maxinteger
	end)
end)

function refuelLoop(isFromJerryCan, fuelAmountPurchased, fuelTypePurchased, fuelNozzle)
	loadNuiVariables()
	local ped = PlayerPedId()
	local inCooldown = false
	local closestCapPos
	local closestVehicle
	local customVehicleParameters
	local closestVehicleHash
	local remainingFuelToRefuel = isFromJerryCan and getJerryCanAmmo() or fuelAmountPurchased
	local refuelingThread
	local vehicleAttachedToNozzle

	local refuelTick = Config.RefuelTick
	local isElectric = false
	-- Change the fuel tick if its electric charging
	if fuelTypePurchased == "electricfast" then
		isElectric = true
		refuelTick = Config.Electric.chargeTypes.fast.time * 1000 / 2 -- Divide by 2 because each tick adds 0.5%.
	end
	if fuelTypePurchased == "electricnormal" then
		isElectric = true
		refuelTick = Config.Electric.chargeTypes.normal.time * 1000 / 2
	end

	local animationDuration = 1000
	if isFromJerryCan then
		animationDuration = -1 -- Do not allow the player walk during refuel from jerry can
	end

	isRefuelling = false
	while DoesEntityExist(fuelNozzle) or (isFromJerryCan and GetSelectedPedWeapon(ped) == JERRY_CAN_HASH) do
		local waitTime = 200
		if closestCapPos then
			distanceToCap = #(GetEntityCoords(ped) - vector3(closestCapPos.x,closestCapPos.y,closestCapPos.z + customVehicleParameters.nozzleOffset.up + 0.0))
			if distanceToCap < customVehicleParameters.distance + 0.0 and (not vehicleAttachedToNozzle or (vehicleAttachedToNozzle and DoesEntityExist(vehicleAttachedToNozzle) and vehicleAttachedToNozzle == closestVehicle)) then
				waitTime = 1
				Utils.Markers.drawText3D(closestCapPos.x,closestCapPos.y,closestCapPos.z + customVehicleParameters.nozzleOffset.up + 0.0, cachedTranslations.interact_with_vehicle)
				if IsControlJustPressed(0, 38) and not inCooldown then
					-- See which one the player is nearer. The fuel cap or fuel pump
					if distanceToPump >= distanceToCap then
						-- Do not allow user mix electric and petrol fuel/vehicles
						if (isElectric and Config.Electric.vehiclesListHash[closestVehicleHash]) or (not isElectric and not Config.Electric.vehiclesListHash[closestVehicleHash]) then
							if not isRefuelling and not vehicleAttachedToNozzle then
								if remainingFuelToRefuel > 0 then
									-- Reset the vehicle fuel to 0 when refueling with a different fuel type
									if not isFromJerryCan and not isElectric then
										local fuelType = getVehicleFuelTypeFromServer(closestVehicle)
										if fuelTypePurchased ~= fuelType then
											changeVehicleFuelType(closestVehicle, fuelTypePurchased)
										end
									end
									isRefuelling = true

									-- Animate the ped for 1 sec
									TaskTurnPedToFaceCoord(ped, closestCapPos.x, closestCapPos.y, closestCapPos.z, animationDuration)
									Utils.Animations.loadAnimDict("weapons@misc@jerrycan@")
									TaskPlayAnim(ped, "weapons@misc@jerrycan@", "fire", 2.0, 8.0, animationDuration, 50, 0, false, false, false)

									-- Plug the nozzle in the car
									attachNozzleToVehicle(closestVehicle, customVehicleParameters)
									vehicleAttachedToNozzle = closestVehicle

									-- Refuel the vehicle
									refuelingThread = CreateThread(function()
										local vehicleToRefuel = closestVehicle
										local startingFuel = GetFuel(vehicleToRefuel) -- Get vehicle fuel level

										-- WIP
										-- local vehicleHash = GetEntityModel(vehicleToRefuel)
										local vehicleTankSize = 100 -- Config.TankSizesHash[vehicleHash] or Config.DefaultTankSize
										-- end WIP

										local currentFuel = startingFuel
										-- Loop keep happening while the player has not canceled, while the fuelNozzle exists and while the ped still has jerry can in hands
										while isRefuelling and (DoesEntityExist(fuelNozzle) or (isFromJerryCan and GetSelectedPedWeapon(ped) == JERRY_CAN_HASH)) do
											currentFuel = GetFuel(vehicleToRefuel)
											local fuelToAdd = 0.5 -- Add 0.5% each tick
											if currentFuel + fuelToAdd > vehicleTankSize then
												-- Increase the vehicle fuel level
												fuelToAdd = vehicleTankSize - currentFuel
											end
											if remainingFuelToRefuel < fuelToAdd then
												-- Break when the user has used all the fuel he paid for
												break
											end
											if fuelToAdd <= 0.1 then
												-- Break when the vehicle tank is full
												exports['lc_utils']:notify("info", Utils.translate("vehicle_tank_full"))
												break
											end
											-- Decrease the purchased fuel amount and increase the vehicle fuel level
											remainingFuelToRefuel = remainingFuelToRefuel - fuelToAdd
											currentFuel = currentFuel + fuelToAdd
											SetFuel(vehicleToRefuel, currentFuel)
											SendNUIMessage({
												showRefuelDisplay = true,
												remainingFuelAmount = remainingFuelToRefuel,
												currentVehicleTank = currentFuel,
												isElectric = isElectric,
												fuelTypePurchased = fuelTypePurchased
											})
											Wait(refuelTick)
										end
										if isFromJerryCan then
											-- Update the jerry can ammo
											SetPedAmmo(ped, JERRY_CAN_HASH, remainingFuelToRefuel)
											updateWeaponAmmo(remainingFuelToRefuel)
										end
										if isElectric then
											exports['lc_utils']:notify("success", Utils.translate("vehicle_recharged"):format(Utils.Math.round(currentFuel - startingFuel, 1)))
										else
											exports['lc_utils']:notify("success", Utils.translate("vehicle_refueled"):format(Utils.Math.round(currentFuel - startingFuel, 1)))
										end
										stopRefuelAction()
										isRefuelling = false
									end)
								else
									exports['lc_utils']:notify("error", Utils.translate("not_enough_refuel"))
								end
							else
								-- Stop refuelling
								stopRefuelAction()
								attachNozzleToPed()
								vehicleAttachedToNozzle = nil
								isRefuelling = false
								-- Cooldown to prevent the user to spam E and glitch things
								inCooldown = true
								SetTimeout(refuelTick + 1,function()
									inCooldown = false
								end)
							end
						else
							exports['lc_utils']:notify("error", Utils.translate("incompatible_fuel"))
						end
					end
				end
			end
		else
			-- Get the closest vehicle and its cap pos
			closestVehicle = GetClosestVehicle()
			closestCapPos = GetVehicleCapPos(closestVehicle)
			closestVehicleHash = GetEntityModel(closestVehicle)
			customVehicleParameters = (Config.CustomVehicleParametersHash[closestVehicleHash] or Config.CustomVehicleParametersHash.default or { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.15, up = 0.5 }, nozzleRotation = { x = 0, y = 0, z = 0} })
			if not closestCapPos then
				print("Cap not found for vehicle")
			end
		end
		Wait(waitTime)
	end

	-- Stop the refueling process
	if refuelingThread then
		TerminateThread(refuelingThread)
	end
end

function stopRefuelAction()
	local ped = PlayerPedId()
	ClearPedTasks(ped)
	RemoveAnimDict("weapons@misc@jerrycan@")
	SendNUIMessage({ hideRefuelDisplay = true })
end

function attachNozzleToVehicle(closestVehicle, customVehicleParameters)
	DetachEntity(fuelNozzle, true, true)

	-- Find the appropriate bone for the fuel cap
	local tankBones = vehicleCapBoneList()
	local boneIndex = -1

	for _, boneName in ipairs(tankBones) do
		boneIndex = GetEntityBoneIndexByName(closestVehicle, boneName)
		if boneIndex ~= -1 then
			break
		end
	end

	if boneIndex ~= -1 then
		local vehicleRotation = GetEntityRotation(closestVehicle)
		local forwardVector, rightVector, upVector, _ = GetEntityMatrix(closestVehicle)

		-- Adjust the offsets
		local forwardOffset = forwardVector * customVehicleParameters.nozzleOffset.forward
		local rightoffset = rightVector * customVehicleParameters.nozzleOffset.right
		local upOffset = upVector * customVehicleParameters.nozzleOffset.up
		local finalOffset = forwardOffset + rightoffset + upOffset

		-- Adjust the rotation
		local nozzleRotation = customVehicleParameters.nozzleRotation or { x = 0, y = 0, z = 0 }
		local finalRotationX = vehicleRotation.x + nozzleRotation.x
		local finalRotationY = vehicleRotation.y + nozzleRotation.y
		local finalRotationZ = vehicleRotation.z + nozzleRotation.z

		-- Attach the nozzle to the vehicle's fuel cap bone with the calculated rotation
		AttachEntityToEntity(fuelNozzle, closestVehicle, boneIndex, finalOffset.x, finalOffset.y, finalOffset.z, finalRotationX - 45, finalRotationY, finalRotationZ - 90, false, false, false, false, 2, false)
	else
		print("No valid fuel cap bone found on the vehicle.")
	end
end

function attachNozzleToPed()
	DetachEntity(fuelNozzle, true, true)

	local ped = PlayerPedId()
	local pedBone = GetPedBoneIndex(ped, 18905)
	AttachEntityToEntity(fuelNozzle, ped, pedBone, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, false, true, false, true, 0, true)
end