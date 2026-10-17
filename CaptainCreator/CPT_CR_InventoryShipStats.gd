@tool
extends InventoryShipStats

class_name CPT_CR_InventoryShipStats

signal StatChanged()

func _ready() -> void:
	super()
	for g : CapCrStatSlider in $GridContainer.get_children():
		g.StatChanged.connect(OnStatChanged)

func OnStatChanged(stat : STAT_CONST.STATS, value : float) -> void:
	StatChanged.emit(stat, value)

func UpdateEditorValues(ShowItemStats : bool) -> void:
	var stats : Dictionary[STAT_CONST.STATS, Dictionary] = {}
	for g in STAT_CONST.STATS.values():
		stats[g] = {"Base" : CurrentShownCaptain.GetStatBaseValue(g), "ShipPartBuff" : 0.0, "ShipPartPenalty" : 0.0}
	
	if (ShowItemStats):
		for g in CurrentShownCaptain.StartingItems:
			
			if (g is ShipPart):
				#Make sure to read the ship part from the mod
				var actualPath = g.resource_path.replace("res:/", Main.dirs.ModDir)
				var actuallPart = load(actualPath)
				for up : ShipPartUpgrade in actuallPart.Upgrades:
					stats[up.UpgradeName]["ShipPartBuff"] += up.UpgradeAmmount
					stats[up.UpgradeName]["ShipPartPenalty"] += up.PenaltyAmmount
				stats[STAT_CONST.STATS.VALUE]["ShipPartBuff"] += actuallPart.Cost
	
	for g in Stats.size():
		var st = stats[Stats[g].STName]
		Stats[g].UpdateStatValue(st["Base"] , st["ShipPartBuff"], st["ShipPartPenalty"])
	
	var thrust = stats[STAT_CONST.STATS.THRUST]["Base"] + stats[STAT_CONST.STATS.THRUST]["ShipPartBuff"] + stats[STAT_CONST.STATS.THRUST]["ShipPartPenalty"]
	var weight = stats[STAT_CONST.STATS.WEIGHT]["Base"] + stats[STAT_CONST.STATS.WEIGHT]["ShipPartBuff"] + stats[STAT_CONST.STATS.WEIGHT]["ShipPartPenalty"]
	
	var Speed = roundi((thrust * 1000) / weight)
	SpeedStat.UpdateStatCustom(0, Speed, 0)
	
	var FuelEf = stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["Base"] + stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["ShipPartBuff"] + stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["ShipPartPenalty"]
	var FuelCap = stats[STAT_CONST.STATS.FUEL_TANK]["Base"] + stats[STAT_CONST.STATS.FUEL_TANK]["ShipPartBuff"] + stats[STAT_CONST.STATS.FUEL_TANK]["ShipPartPenalty"]
	
	var eff_eff = (FuelEf / pow(weight, 0.5)) * 10
	var ShipRange = roundi(FuelCap * eff_eff)
	Rangestat.UpdateStatCustom(0, ShipRange, 0)
	
	var NormalisedThrust = Helper.normalize_value(thrust, 0, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.THRUST))
	NoiseStat.UpdateStatCustom(0, roundi(Helper.mapvalue(NormalisedThrust, 50, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.THRUST))), 0)
	
	var ChValue = CurrentShownCaptain.ProvidingFunds
	var Itvalue = stats[STAT_CONST.STATS.VALUE]["Base"] + stats[STAT_CONST.STATS.VALUE]["ShipPartBuff"] + stats[STAT_CONST.STATS.VALUE]["ShipPartPenalty"]
	ValueStat.UpdateStatCustom(ChValue, Itvalue, 0)
