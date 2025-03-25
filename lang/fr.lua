if not Lang then Lang = {} end
Lang['fr'] = {
    ['markers'] = {
        ['open_refuel'] = "Appuyez sur ~INPUT_CONTEXT~ pour faire le plein",
        ['open_recharge'] = "Appuyez sur ~INPUT_CONTEXT~ pour recharger",
        ['interact_with_vehicle'] = "Appuyez sur ~y~E~w~ pour interagir",
        ['return_nozzle'] = "Appuyez sur ~INPUT_CONTEXT~ pour remettre le pistolet",
    },
    ['target'] = {
        ['open_refuel'] = "Ouvrir le menu de ravitaillement",
        ['open_recharge'] = "Ouvrir le menu de recharge",
        ['start_refuel'] = "Faire le plein du véhicule",
        ['stop_refuel'] = "Arrêter le ravitaillement",
        ['return_nozzle'] = "Ranger le pistolet",
    },
    ['blip_text'] = "Stations-service",
    ['not_enough_refuel'] = "Vous avez déjà utilisé tout le carburant que vous avez payé. Veuillez acheter plus de carburant si nécessaire",
    ['invalid_value'] = "Valeur invalide",
    ['not_enough_money'] = "Vous n'avez pas $%s pour payer cela",
    ['not_enough_stock'] = "Cette station-service n'a pas assez de stock pour effectuer cette action",
    ['refuel_paid'] = "Vous avez payé $%s pour ce ravitaillement",
    ['returned_fuel'] = "Vous avez rendu %sL de carburant et récupéré $%s",
    ['jerry_can_paid'] = "Vous avez payé $%s pour ce bidon d'essence",
    ['too_far_away'] = "Vous êtes trop loin de la pompe",
    ['vehicle_refueled'] = "Vous avez mis %sL dans le véhicule",
    ['vehicle_recharged'] = "Vous avez rechargé %skWh dans le véhicule",
    ['vehicle_tank_full'] = "Le réservoir du véhicule est plein",
    ['vehicle_tank_emptied'] = "Le réservoir du véhicule est vide",
    ['vehicle_not_found'] = "Véhicule non trouvé",
    ['pump_not_found'] = "Pompe non trouvée",
    ['vehicle_wrong_fuel'] = "Vous avez utilisé le mauvais type de carburant pour ce véhicule, ce qui l'a endommagé.",
    ['incompatible_fuel'] = "Type de carburant incompatible détecté. Veuillez sélectionner la bonne option de ravitaillement pour votre véhicule.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "Bidon d'essence vendu (%s Litres)",
        ['balance_fuel'] = "Carburant vendu (%s Litres)",
        ['balance_electric'] = "Charge électrique vendue (%s kWh)",
    }
}