if not Lang then Lang = {} end
Lang['en'] = {
    ['markers'] = {
        ['open_refuel'] = "Press ~INPUT_CONTEXT~ to refuel",
        ['open_recharge'] = "Press ~INPUT_CONTEXT~ to recharge",
        ['interact_with_vehicle'] = "Press ~y~E~w~ to interact",
        ['return_nozzle'] = "Press ~INPUT_CONTEXT~ to return the nozzle",
    },
    ['target'] = {
        ['open_refuel'] = "Open refuel menu",
        ['open_recharge'] = "Open recharge menu",
        ['start_refuel'] = "Refuel vehicle",
        ['stop_refuel'] = "Stop refuel",
        ['return_nozzle'] = "Return the nozzle",
    },
    ['blip_text'] = "Gas stations",
    ['not_enough_refuel'] = "You've already used all the fuel you paid for. Please purchase additional fuel if needed",
    ['invalid_value'] = "Invalid value",
    ['not_enough_money'] = "You don't have $%s to pay this",
    ['not_enough_stock'] = "This gas station don't have enough stock to perform this action",
    ['refuel_paid'] = "Paid $%s for this refuel",
    ['jerry_can_paid'] = "Paid $%s for this jerry can",
    ['too_far_away'] = "You are too far from the pump",
    ['vehicle_refueled'] = "You refueled %sL in the vehicle",
    ['vehicle_recharged'] = "You recharged %skWh in the vehicle",
    ['vehicle_tank_full'] = "Vehicle tank is full",
    ['vehicle_tank_emptied'] = "Vehicle tank emptied",
    ['vehicle_not_found'] = "Vehicle not found",
    ['pump_not_found'] = "Pump not found",
    ['vehicle_wrong_fuel'] = "You used the wrong fuel type for this vehicle, causing it to break down.",
    ['incompatible_fuel'] = "Incompatible fuel type detected. Please select the correct refueling option for your vehicle.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "Gas can sold (%s Liters)",
        ['balance_fuel'] = "Fuel sold (%s Liters)",
        ['balance_electric'] = "Electric charge sold (%s kWh)",
    }
}