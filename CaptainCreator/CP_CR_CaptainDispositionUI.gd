@tool
extends CaptainDispositionUI

class_name CP_CR_CaptainDispositionUI

func GetCharacterEditorDisp(ch : Captain) -> void:
	for g in CharacterStats:
		CharacterStats[g] = ch.disp[g]
		ItemStats[g] = 0
	for g in ch.StartingItems:
		if (g is ShipPart):
			#Make sure to load item from mod
			var actualPath = g.resource_path.replace("res:/", Main.dirs.ModDir)
			var actuallIt : ShipPart = load(actualPath)
			ItemStats[actuallIt.disp] += actuallIt.DispositionAmm
