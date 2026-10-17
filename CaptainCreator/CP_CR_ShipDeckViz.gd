extends ShipDeckViz

class_name CP_CR_ShipDeckViz


func SetDeck(Ch : Captain) -> void:
	#var msBefore = Time.get_ticks_msec()
	var Inv = Ch.GetCharacterInventory()
	
	deckSize = 0
	CardToMake.clear()
	
	if (Inv != null):
		if (CurrentlyShownCharacter != Ch):
			if (CurrentlyShownCharacter != null and CurrentlyShownCharacter.GetCharacterInventory() != null):
				CurrentlyShownCharacter.GetCharacterInventory().InventoryUpdated.disconnect(InventoryUpdated)
			CurrentlyShownCharacter = Ch
			Inv.InventoryUpdated.connect(InventoryUpdated)
		CardToMake = GetCardDictionary(Inv)
		var dispositionCards : Dictionary[CardStats, int] = DispositionManager.Instance.GetRewards(Ch)
	
		for g in dispositionCards:
			if (CardToMake.has(g)):
				CardToMake[g] += dispositionCards[g]
			else:
				CardToMake[g] = dispositionCards[g]
	else:
		CardToMake = Ch.GetStartingDeck()

	
	for g in OffensiveCardPosition.get_children():
		PooledCards.append(g)
		#OffensiveCardPosition.remove_child(g)
	for g in DeffencsiveCardPosition.get_children():
		PooledCards.append(g)
		#DeffencsiveCardPosition.remove_child(g)
	for g in UtilityCardPosition.get_children():
		PooledCards.append(g)
		#UtilityCardPosition.remove_child(g)
		#g.queue_free()
	for g in PowerCardPosition.get_children():
		PooledCards.append(g)
		#PowerCardPosition.remove_child(g)
	
	for g in PooledCards:
			var parent = g.get_parent()
			if (parent):
				g.get_parent().remove_child(g)


func _physics_process(_delta: float) -> void:
	if (CardToMake.size() > 0):
		var card : CardStats = CardToMake.keys().pop_back()
		var c : Card
		deckSize += CardToMake[card]
		if (PooledCards.size() > 0):
			c = PooledCards.pop_back()

			GetParentForCard(card).add_child(c)
		else:
			c = CardScene.instantiate()
			GetParentForCard(card).add_child(c)
			
		var actualPath = card.resource_path.replace("res:/", Main.dirs.ModDir)
		var actualCard = load(actualPath)
		c.SetCardStats(actualCard, CardToMake[card])
		c.Dissable()
		
		CardToMake.erase(card)
		
		
		sizeLabel.text = "Deck Size : {0}".format([deckSize])
		#print("Pooled = {0}".format([PooledCards.size()]))
		#var msAfter = Time.get_ticks_msec()
		#print("Card Setting took {0}".format([msAfter - msBefore]))

func GetCardDictionary(inv : CharacterInventory) -> Dictionary[CardStats, int]:
	var c : Dictionary[CardStats, int]
	for g in inv._InventoryContents:
		var actualPath = g.resource_path.replace("res:/", Main.dirs.ModDir)
		var actuallItem : Item = load(actualPath)
		for v in inv._InventoryContents[g]:
			
			if (actuallItem is AmmoItem and !inv.HasWeapon(actuallItem.WType)):
				continue
			if (actuallItem is MissileItem and !inv.HasWeapon(CardStats.WeaponType.ML)):
				continue
			for z in actuallItem.CardProviding:
				var C = z as CardStats
				C.Tier = actuallItem.Tier
				
				var Added = false
				
				for Ca : CardStats in c.keys():
					if (Ca.IsSame(C)):
						c[Ca] += 1
						Added = true
						break
				if (!Added):
					c[C] = 1

	return c
