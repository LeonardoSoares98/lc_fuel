if (Lang == undefined) {
	var Lang = [];
}
Lang["tr"] = {
	pumpInterface: {
		stationStock: "{0} L",
		vehicleFuel: "{0} L",
		confirm: "ONAYLA",
		fuelTypes: {
			regular: "Normal",
			plus: "Plus",
			premium: "Premium",
			diesel: "Dizel",
		},
	},
	pumpRefuelDisplay: {
		liters: "L",
		carTank: "Araç Deposu",
		remaining: "Kalan",
	},
	confirmRefuelModal: {
		title: "Yakıt Alımını Onayla",
		description: "{0}L {1} yakıtı {2} karşılığında satın alıyorsunuz.",
		paymentBank: "Banka ile öde",
		paymentCash: "Nakit ile öde",
	},
	confirmBuyJerryCanModal: {
		title: "Satın Alımı Onayla",
		paymentBank: "Banka ile öde",
		paymentCash: "Nakit ile öde",
	},
	confirmFuelChangeModal: {
		title: "Yakıtlar Karıştırılamaz",
		description: "⚠️ Araçtaki yakıt türünü değiştirmek için depo boşaltılacaktır.",
	},
	electricInterface: {
		chargerType: {
			title: "ŞARJ CİHAZI TÜRÜ",
			fast: {
				title: "HIZLI",
				power: "220kW",
			},
			normal: {
				title: "NORMAL",
				power: "100kW",
			},
			pricePerKWh: "{0}/kWh",
		},
		chargerAmount: {
			title: "MİKTAR SEÇİN",
			typeSelected: "{0} ŞARJ CİHAZI",
			placeholder: "Miktar",
			timeToRechargeText: "Şarj süresi:",
			timeToRechargeValue: "{0} dk {1} sn",
		},
		chargerPayment: {
			title: "ÖDEME YÖNTEMİ",
			money: "NAKİT",
			bank: "BANKA",
			payButton: "{0} ÖDE",
		},
		continueButton: "DEVAM",
		outOfStock: "Stokta yok",
	},
	rechargerDisplay: {
		title: "ŞARJ EDİLİYOR...",
		remainingTimeText: "KALAN SÜRE",
		remainingTimeValue: "{0} dk {1} sn",
	},
};
