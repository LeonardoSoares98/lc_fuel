if not Lang then Lang = {} end
Lang['de'] = {
    ['markers'] = {
        ['open_refuel'] = "Drücke ~INPUT_CONTEXT~, um zu tanken",
        ['open_recharge'] = "Drücke ~INPUT_CONTEXT~, um aufzuladen",
        ['interact_with_vehicle'] = "Drücke ~y~E~w~, um zu interagieren",
        ['return_nozzle'] = "Drücke ~INPUT_CONTEXT~, um die Zapfpistole zurückzugeben",
    },
    ['target'] = {
        ['open_refuel'] = "Tankmenü öffnen",
        ['open_recharge'] = "Lademenü öffnen",
        ['start_refuel'] = "Fahrzeug betanken",
        ['stop_refuel'] = "Tanken beenden",
        ['return_nozzle'] = "Zapfpistole zurückgeben",
    },
    ['blip_text'] = "Tankstelle",
    ['not_enough_refuel'] = "Sie haben den gesamten bezahlten Kraftstoff bereits verbraucht. Bitte kaufen Sie bei Bedarf zusätzlichen Treibstoff",
    ['invalid_value'] = "Ungültiger Wert",
    ['not_enough_money'] = "Du hast nicht genug $%s geld um das zu Bezahlen",
    ['not_enough_stock'] = "Diese Tankstelle verfügt nicht über genügend Lagerbestände, um diese Aktion durchzuführen",
    ['refuel_paid'] = "$%s bezahlt zum Tanken",
    ['returned_fuel'] = "Du hast %sL Kraftstoff zurückgegeben und $%s zurückerhalten",
    ['returned_charge'] = "Du hast %skWh Ladung zurückgegeben und $%s zurückerhalten",
    ['jerry_can_paid'] = "$%s bezahlt für den Kanister",
    ['too_far_away'] = "Sie sind zu weit von der Zapfseule entfernt",
    ['vehicle_refueled'] = "Sie haben %sL ins Fahrzeug getankt",
    ['vehicle_recharged'] = "Sie haben %skWh im Fahrzeug aufgeladen",
    ['vehicle_tank_full'] = "Auto ist voll getankt",
    ['vehicle_tank_emptied'] = "Fahrzeugtank ist leer",
    ['vehicle_not_found'] = "Fahrzeug konnte nicht gefunden werden",
    ['pump_not_found'] = "Zapfseule konnte nicht gefunden werden",
    ['vehicle_wrong_fuel'] = "Sie haben für dieses Fahrzeug den falschen Kraftstofftyp verwendet, was zu einer Panne geführt hat.",
    ['incompatible_fuel'] = "Inkompatibler Kraftstofftyp erkannt. Bitte wählen Sie die richtige Betankungsoption für Ihr Fahrzeug aus.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "Benzinkanister verkauft (%s Liter)",
        ['balance_fuel'] = "Treibstoff verkauft (%s Liter)",
        ['balance_electric'] = "Elektrische Ladung verkauft (%s kWh)",
    }
}
