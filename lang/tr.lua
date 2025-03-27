if not Lang then Lang = {} end
Lang['tr'] = {
    ['markers'] = {
        ['open_refuel'] = "Yakıt almak için ~INPUT_CONTEXT~ tuşuna basın",
        ['open_recharge'] = "Şarj etmek için ~INPUT_CONTEXT~ tuşuna basın",
        ['interact_with_vehicle'] = "Etkileşim için ~y~E~w~ tuşuna basın",
        ['return_nozzle'] = "Tabancayı geri koymak için ~INPUT_CONTEXT~ tuşuna basın",
    },
    ['target'] = {
        ['open_refuel'] = "Yakıt menüsünü aç",
        ['open_recharge'] = "Şarj menüsünü aç",
        ['start_refuel'] = "Araca yakıt doldur",
        ['stop_refuel'] = "Yakıt doldurmayı durdur",
        ['return_nozzle'] = "Tabancayı geri koy",
    },
    ['blip_text'] = "Benzin istasyonları",
    ['not_enough_refuel'] = "Zaten ödediğiniz tüm yakıtı kullandınız. Gerekirse ek yakıt satın alın",
    ['invalid_value'] = "Geçersiz değer",
    ['not_enough_money'] = "Bunu ödemek için $%s paranız yok",
    ['not_enough_stock'] = "Bu benzin istasyonunda bu işlemi gerçekleştirmek için yeterli stok yok",
    ['refuel_paid'] = "Bu yakıt için $%s ödendi",
    ['returned_fuel'] = "%sL yakıtı iade ettiniz ve $%s geri aldınız",
    ['jerry_can_paid'] = "Bu bidon için $%s ödendi",
    ['too_far_away'] = "Pompadan çok uzaktasınız",
    ['vehicle_refueled'] = "Araca %sL yakıt dolduruldu",
    ['vehicle_recharged'] = "Araca %skWh şarj yapıldı",
    ['vehicle_tank_full'] = "Araç deposu dolu",
    ['vehicle_tank_emptied'] = "Araç deposu boşaltıldı",
    ['vehicle_not_found'] = "Araç bulunamadı",
    ['pump_not_found'] = "Pompa bulunamadı",
    ['vehicle_wrong_fuel'] = "Bu araç için yanlış yakıt kullandınız ve aracınız bozuldu.",
    ['incompatible_fuel'] = "Uyumsuz yakıt türü tespit edildi. Lütfen aracınız için doğru yakıt seçeneğini seçin.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "Yakıt bidonu satıldı (%s Litre)",
        ['balance_fuel'] = "Yakıt satıldı (%s Litre)",
        ['balance_electric'] = "Elektrik şarjı satıldı (%s kWh)",
    }
}
