Config = {}

Config.EnablePumpRope = true	-- Enable/disable the pump rope
Config.DefaultRopeLength = 7.5	-- Pump rope length
Config.EnableHUD = false		-- Simple hud to show current fuel and consumption
Config.RefuelTick = 300 		-- Time in ms to refuel 0.5L of fuel in the vehicle (lower values means faster refuel)
Config.NozzleProps = {			-- Props used in the script
	gas = "prop_cs_fuel_nozle",
	electric = "prop_eletricpistol",
}

-- JerryCan settings
Config.JerryCan = {
	enabled = true,				-- Enable/disable jerry cans purchase
	price = 300,				-- Price to purchase it
	requiredStock = 10,			-- Amount of stock required in gas station to provide a jerry can
	item = "weapon_petrolcan",	-- Jerry can inventory item
	giveAsWeapon = true,		-- true: Give jerry can as weapon | false: Give jerry can as item
	metadata = { ammo = 100 }	-- Item metadata
}

-- Accounts the user can choose when purchasing fuel
Config.Accounts = {
	account1 = "cash",
	account2 = "bank",
}

-- Players inside these jobs will receive the specified discounts
Config.JobDiscounts = {
	["police"] = 90, 			-- The job name (NOT THE LABEL), and the discount amount in % this job will receive
	["ambulance"] = 80,
}

-- Config for not owned gas stations
Config.DefaultValues = {
	-- Default price for each type
	fuelPrice = {
		regular = 1.55,
		plus = 1.69,
		premium = 1.98,
		diesel = 1.49,
	},
	-- Set if the pump will have stock of each fuel type or not when not owned
	fuelStock = {
		regular = true,
		plus = true,
		premium = true,
		diesel = true,
	}
}

-- Config for linking the gas pumps to player owned gas stations
Config.PlayerOwnedGasStations = {
	enabled = false,			-- Enable/disable retrieve fuel price and stock from player owned gas stations
	gasStations = {				-- This list is the vector3 + radius of center of the gas pumps area, so the script can know which gas pump is from which gas station
		["gas_station_1"] = {								-- Gas station id (same from gas station script config)
			vector = vector3(264.95, -1259.45, 29.14),		-- Center of the gas pumps area
			radius = 30										-- Radius of the area (30 meters usually works fine, but larger gas stations may require a larger area)
		},
		["gas_station_2"] = {
			vector = vector3(819.61, -1028.21, 26.40),
			radius = 30
		},
		["gas_station_3"] = {
			vector = vector3(1208.61, -1402.29, 35.22),
			radius = 30
		},
		["gas_station_4"] = {
			vector = vector3(1180.96, -329.84, 69.32),
			radius = 30
		},
		["gas_station_5"] = {
			vector = vector3(620.80, 268.74, 103.09),
			radius = 30
		},
		["gas_station_6"] = {
			vector = vector3(2581.18, 362.01, 108.47),
			radius = 30
		},
		["gas_station_7"] = {
			vector = vector3(175.56, -1562.21, 29.26),
			radius = 30
		},
		["gas_station_8"] = {
			vector = vector3(-319.43, -1471.82, 30.55),
			radius = 30
		},
		["gas_station_9"] = {
			vector = vector3(1785.90, 3330.90, 41.38),
			radius = 30
		},
		["gas_station_10"] = {
			vector = vector3(49.80, 2779.32, 58.04),
			radius = 30
		},
		["gas_station_11"] = {
			vector = vector3(263.92, 2607.41, 44.98),
			radius = 30
		},
		["gas_station_12"] = {
			vector = vector3(1039.12, 2671.31, 39.55),
			radius = 30
		},
		["gas_station_13"] = {
			vector = vector3(1208.04, 2660.49, 37.90),
			radius = 30
		},
		["gas_station_14"] = {
			vector = vector3(2539.33, 2594.61, 37.94),
			radius = 30
		},
		["gas_station_15"] = {
			vector = vector3(2679.94, 3264.10, 55.24),
			radius = 30
		},
		["gas_station_16"] = {
			vector = vector3(2005.01, 3774.20, 32.40),
			radius = 30
		},
		["gas_station_17"] = {
			vector = vector3(1687.26, 4929.63, 42.08),
			radius = 30
		},
		["gas_station_18"] = {
			vector = vector3(1702.01, 6417.00, 32.76),
			radius = 30
		},
		["gas_station_19"] = {
			vector = vector3(165.68, 6616.95, 31.90),
			radius = 50
		},
		["gas_station_20"] = {
			vector = vector3(-94.21, 6419.50, 31.49),
			radius = 30
		},
		["gas_station_21"] = {
			vector = vector3(-2555.13, 2334.27, 33.08),
			radius = 30
		},
		["gas_station_22"] = {
			vector = vector3(-1799.42, 802.82, 138.65),
			radius = 30
		},
		["gas_station_23"] = {
			vector = vector3(-1436.97, -276.55, 46.21),
			radius = 30
		},
		["gas_station_24"] = {
			vector = vector3(-2096.59, -321.49, 13.17),
			radius = 30
		},
		["gas_station_25"] = {
			vector = vector3(-723.30, -935.55, 19.21),
			radius = 30
		},
		["gas_station_26"] = {
			vector = vector3(-525.35, -1211.32, 18.18),
			radius = 30
		},
		["gas_station_27"] = {
			vector = vector3(-70.51, -1761.26, 29.66),
			radius = 30
		},
	}
}

-- These are the vehicles that accept diesel. Put any fuel different than diesel in these vehicles will break their engines
Config.DieselVehicles = {
	"benson",
	"benson2",
	"biff",
	"cerberus",
	"cerberus2",
	"cerberus3",
	"hauler",
	"hauler2",
	"mule",
	"mule2",
	"mule3",
	"mule4",
	"mule5",
	"packer",
	"phantom",
	"phantom2",
	"phantom3",
	"phantom4",
	"pounder",
	"pounder2",
	"stockade",
	"stockade3",
	"terbyte",

	"bulldozer",
	"cutter",
	"dump",
	"flatbed",
	"handler",
	"mixer",
	"mixer2",
	"rubble",
	"tiptruck",
	"tiptruck2",

	"barracks",
	"barracks2",
	"barracks3",
	"vetir",

	"airbus",
	"brickade",
	"brickade2",
	"bus",
	"coach",
	"pbus2",
	"trash",
	"trash2",

	"aerocab",
	"blacktop",
	"brickades",
	"linerunner",
	"vetirs",
}

-- Fuel consumption multiplier per fuel type
-- Lower values means more economic
Config.FuelConsumptionPerFuelType = {
	regular = 1.0,
	plus = 0.9,
	premium = 0.8,
	diesel = 1.0,
}

-- Fuel consumption multiplier per vehicle class
-- Lower values means more economic
Config.FuelConsumptionPerClass = {
	[0] = 0.6, -- Compacts
	[1] = 0.9, -- Sedans
	[2] = 1.1, -- SUVs
	[3] = 0.8, -- Coupes
	[4] = 1.2, -- Muscle
	[5] = 1.2, -- Sports Classics
	[6] = 1.1, -- Sports
	[7] = 1.2, -- Super
	[8] = 0.4, -- Motorcycles
	[9] = 1.3, -- Off-road
	[10] = 1.9, -- Industrial
	[11] = 1.7, -- Utility
	[12] = 1.6, -- Vans
	[13] = 0.0, -- Cycles
	[14] = 1.0, -- Boats
	[15] = 1.0, -- Helicopters
	[16] = 1.0, -- Planes
	[17] = 1.0, -- Service
	[18] = 1.0, -- Emergency
	[19] = 1.0, -- Military
	[20] = 1.8, -- Commercial
	[21] = 1.0, -- Trains
}

-- Vehicle fuel usage per RPM
Config.FuelUsage = {
	[1.0] = 1.3,
	[0.9] = 1.1,
	[0.8] = 0.9,
	[0.7] = 0.8,
	[0.6] = 0.7,
	[0.5] = 0.5,
	[0.4] = 0.3,
	[0.3] = 0.2,
	[0.2] = 0.1,
	[0.1] = 0.1,
	[0.0] = 0.0,
}

-- Gas pump props and offset for the fuel rope
Config.GasPumpProps = {
	{
		prop = "prop_gas_pump_1d",	-- Prop name
		ropeOffset = {				-- Rope attachment offset
			forward = 0.0,			-- Forward/backward offset
			right = 0.0,			-- Left/right offset
			up = 2.3				-- Vertical offset
		}
	},
	{ prop = "prop_gas_pump_1a", ropeOffset = { forward = 0.0, right = 0.0, up = 2.3 } },
	{ prop = "prop_gas_pump_1b", ropeOffset = { forward = 0.0, right = 0.0, up = 2.3 } },
	{ prop = "prop_gas_pump_1c", ropeOffset = { forward = 0.0, right = 0.0, up = 2.3 } },
	{ prop = "prop_vintage_pump", ropeOffset = { forward = 0.0, right = 0.0, up = 1.8 } },
	{ prop = "prop_gas_pump_old2", ropeOffset = { forward = 0.0, right = 0.0, up = 1.6 } },
	{ prop = "prop_gas_pump_old3", ropeOffset = { forward = 0.0, right = 0.0, up = 1.6 } },
}

-- Add here locations for gas pumps props to spawn
Config.CustomGasPumpLocations = {
	{ prop = "prop_gas_pump_1b", location = vector4(442.2, -977.17, 42.69, 270.3), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(362.65, -592.64, 73.16, 71.26), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(301.12, -1465.61, 45.51, 321.3), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-923.12, -2976.81, 12.95, 149.55), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-1665.44, -3104.53, 12.94, 329.89), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-706.13, -1464.14, 4.04, 320.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-764.81, -1434.32, 4.06, 320.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-805.9, -1496.68, 0.6, 200.00), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-2148.8, 3283.99, 31.81, 240.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-486.22, 5977.65, 30.3, 315.4), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(2101.82, 4776.8, 40.02, 21.41), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(1338.13, 4269.62, 30.5, 85.00), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-1089.72, -830.6, 36.68, 129.00), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(483.28, -3382.83, 5.07, 0.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-1158.29, -2848.67, 12.95, 240.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(-1125.15, -2866.97, 12.95, 240.0), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(1771.81, 3229.24, 41.51, 15.00), ropeLength = 14.0 },
	{ prop = "prop_gas_pump_1b", location = vector4(1748.31, 3297.08, 40.16, 15.0), ropeLength = 14.0 },
}

-- Vehicles that dont use fuel
Config.BlacklistedVehicles = {
    "bmx",
    "cruiser",
    "fixter",
    "scorcher",
    "tribike",
    "tribike2",
    "tribike3",
}

-- Custom parameters based on vehicle (Add vehicles in this list is optional, but if you want everything to be perfect, then you should).
Config.CustomVehicleParameters = {
	["default"] = { 			-- Default configuration for vehicles not listed in this list
		distance = 1.2,			-- Interaction distance (larger vehicles need a bigger value)
		nozzleOffset = {		-- Nozzle attachment offset
			forward = 0.0,		-- Forward/backward offset
			right = -0.15,		-- Left/right offset
			up = 0.5			-- Vertical offset
		},
		nozzleRotation = {		-- (optional) Nozzle rotation
			x = 0, y = 0, z = 0
		}
	},

	-- Examples:
	-- Cars
	["asbo"] = { distance = 1.2, nozzleOffset = { forward = 0.0, right = -0.21, up = 0.50} },
	-- Trucks
	["benson"] = { distance = 1.2, nozzleOffset = { forward = 0.3, right = 0.32, up = 0.19 }, nozzleRotation = { x = 0, y = 0, z = 180} },
}

-- Electric
Config.Electric = {
	enabled = true,						-- Enable/ disable electric things
	chargersLocation = {				-- Location of the props
		{ prop = "prop_electric_01", location = vector4(175.9, -1546.65, 28.26, 225.29), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-51.09, -1767.02, 28.26, 48.16), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-514.06, -1216.25, 17.46, 67.29), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-704.64, -935.71, 18.21, 91.02), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(279.79, -1237.35, 28.35, 182.07), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(834.27, -1028.7, 26.16, 89.39), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1194.41, -1394.44, 34.37, 271.3), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1168.38, -323.56, 68.3, 281.22), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(633.64, 247.22, 102.3, 61.29), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-1420.51, -278.76, 45.26, 138.35), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-2080.61, -338.52, 12.26, 353.21), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-98.12, 6403.39, 30.64, 142.49), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(181.14, 6636.17, 30.61, 180.96), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1714.14, 6425.44, 31.79, 156.94), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1703.57, 4937.23, 41.08, 56.74), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1994.54, 3778.44, 31.18, 216.25), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1770.86, 3337.97, 40.43, 302.1), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(2690.25, 3265.62, 54.24, 59.98), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(1033.32, 2662.91, 38.55, 96.38), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(267.96, 2599.47, 43.69, 6.8), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(50.21, 2787.38, 56.88, 148.2), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-2570.04, 2317.1, 32.22, 22.29), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(2545.81, 2586.18, 36.94, 84.74), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(2561.24, 357.3, 107.62, 267.65), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-1819.22, 798.51, 137.16, 316.13), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-341.63, -1459.39, 29.76, 272.73), ropeLength = 7.5 },
		{ prop = "prop_electric_01", location = vector4(-3099.4470, 1431.6660, 19.6253, 326.2006), ropeLength = 7.5 },
	},
	chargersProps = {					-- List of the props and their offsets to fuel rope
		{ prop = "prop_electric_01", ropeOffset = { forward = 0.0, right = 0.25, up = 0.3 } },
	},
	-- Fast / Normal types
	chargeTypes = {
		fast = {
			price = 2.5,				-- Price per 1% recharged
			time = 0.8,					-- Time in seconds to recharge 0.5% of battery in the vehicle (lower values means faster refuel)
			stock = true				-- Set if the charger will have stock when not owned 
		},
		normal = {
			price = 1.8,
			time = 2,
			stock = true
		}
	},
	vehiclesList = {					-- Electric vehicles list
		"voltic",
		"voltic2",
		"caddy",
		"caddy2",
		"caddy3",
		"surge",
		"iwagen",
		"raiden",
		"airtug",
		"neon",
		"omnisegt",
		"cyclone",
		"tezeract",
		"rcbandito",
		"imorgon",
		"dilettante",
		"dilettante2",
		"khamelion",
	}
}