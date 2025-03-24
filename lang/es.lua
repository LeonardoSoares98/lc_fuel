if not Lang then Lang = {} end
Lang['es'] = {
    ['markers'] = {
        ['open_refuel'] = "Pulsa ~INPUT_CONTEXT~ para repostar",
        ['open_recharge'] = "Pulsa ~INPUT_CONTEXT~ para cargar",
        ['interact_with_vehicle'] = "Pulsa ~y~E~w~ para interactuar",
        ['return_nozzle'] = "Pulsa ~INPUT_CONTEXT~ para devolver la manguera",
    },
    ['target'] = {
        ['open_refuel'] = "Abrir menú de repostaje",
        ['open_recharge'] = "Abrir menú de carga",
        ['start_refuel'] = "Repostar vehículo",
        ['stop_refuel'] = "Detener repostaje",
        ['return_nozzle'] = "Devolver la manguera",
    },
    ['blip_text'] = "Gasolineras",
    ['not_enough_refuel'] = "Ya has usado todo el combustible que pagaste. Compra más combustible si es necesario",
    ['invalid_value'] = "Valor inválido",
    ['not_enough_money'] = "No tienes $%s para pagar esto",
    ['not_enough_stock'] = "Esta gasolinera no tiene suficiente stock para realizar esta acción",
    ['refuel_paid'] = "Pagaste $%s por este repostaje",
    ['jerry_can_paid'] = "Pagaste $%s por este bidón de gasolina",
    ['too_far_away'] = "Estás demasiado lejos del surtidor",
    ['vehicle_refueled'] = "Repostaste %sL en el vehículo",
    ['vehicle_recharged'] = "Recargaste %skWh en el vehículo",
    ['vehicle_tank_full'] = "El tanque del vehículo está lleno",
    ['vehicle_tank_emptied'] = "El tanque del vehículo se ha vaciado",
    ['vehicle_not_found'] = "Vehículo no encontrado",
    ['pump_not_found'] = "Surtidor no encontrado",
    ['vehicle_wrong_fuel'] = "Usaste el tipo de combustible incorrecto para este vehículo, causando que se averíe.",
    ['incompatible_fuel'] = "Tipo de combustible incompatible detectado. Por favor, selecciona la opción de repostaje correcta para tu vehículo.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "Bidón de gasolina vendido (%s Litros)",
        ['balance_fuel'] = "Combustible vendido (%s Litros)",
        ['balance_electric'] = "Carga eléctrica vendida (%s kWh)",
    }
}
