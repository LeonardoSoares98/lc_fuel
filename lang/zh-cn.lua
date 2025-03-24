if not Lang then Lang = {} end
Lang['zh-cn'] = {
    ['markers'] = {
        ['open_refuel'] = "按下 ~INPUT_CONTEXT~ 进行加油",
        ['open_recharge'] = "按下 ~INPUT_CONTEXT~ 进行充电",
        ['interact_with_vehicle'] = "按下 ~y~E~w~ 与车辆交互",
        ['return_nozzle'] = "按下 ~INPUT_CONTEXT~ 归还油枪",
    },
    ['target'] = {
        ['open_refuel'] = "进行加油",
        ['open_recharge'] = "进行充电",
        ['start_refuel'] = "开始加油",
        ['stop_refuel'] = "终止加油",
        ['return_nozzle'] = "归还油枪",
    },
    ['blip_text'] = "加油站",
    ['not_enough_refuel'] = "您已用完所支付的燃油。如需继续，请购买更多燃油",
    ['invalid_value'] = "无效数值",
    ['not_enough_money'] = "您的账户余额不足支付当前金额 ($%s) ",
    ['not_enough_stock'] = "本站点当前无充足库存完成该操作",
    ['refuel_paid'] = "本次燃油补给消费 $%s",
    ['jerry_can_paid'] = "本次便携油桶购买消费 $%s",
    ['too_far_away'] = "您与加油设备间距超出操作范围!",
    ['vehicle_refueled'] = "车辆成功加注燃油 %s 升(L)",
    ['vehicle_recharged'] = "车辆成功充入电能 %s 千瓦时(kWh)",
    ['vehicle_tank_full'] = "车辆油箱已达最大容量",
    ['vehicle_tank_emptied'] = "车辆油箱燃油已全部清空",
    ['vehicle_not_found'] = "未检测到关联载具",
    ['pump_not_found'] = "未检测到可用加油设备",
    ['vehicle_wrong_fuel'] = "误用燃油类型导致车辆受损, 请立即停止操作!",
    ['incompatible_fuel'] = "燃油类型与车辆配置不匹配，请选择适配的加油方案.",
    ['owned_gas_stations'] = {
        ['balance_jerry_can'] = "便携式油桶销售量 (%s 升)",
        ['balance_fuel'] = "燃油销售总量 (%s 升)",
        ['balance_electric'] = "电能销售收入 (%s 千瓦时)",
    }
}