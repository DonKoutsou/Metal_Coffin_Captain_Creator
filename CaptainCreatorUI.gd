@tool
extends ScrollContainer

var Captains : Array[Captain]
var Items : Array[Item]
var CurrentlySelectedCap : Captain


@export var StatScene : PackedScene
@export var ItemBoxScene : PackedScene
@export_group("Captain Info Nodes")
@export var CaptainName : TextEdit
@export var CaptainDesc : TextEdit
@export var CaptainProtrait : TextureRect
@export var ShipIcon : TextureRect
@export var ItemGrid : GridContainer

var ShowItemStats = true

func _enter_tree() -> void:
	RefreshCharacters()
	RefrshExistingItems()
	
func RefreshCharacters() -> void:
	var dir = DirAccess.open("res://Resources/Captains/PlayerCaptains")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var c = load("res://Resources/Captains/PlayerCaptains/" + file_name)
			Captains.append(c)
			file_name = dir.get_next()
	
	var Menu = $"VBoxContainer/PanelContainer2/MenuBar/Select Captain" as PopupMenu
	while Menu.item_count > 0:
		Menu.remove_item(0)
	for g in Captains.size():
		Menu.add_item(Captains[g].CaptainName, g)
	
	SetCaptain(Captains[0])

func RefrshExistingItems() -> void:
	var DirsToExplore :Array[String] = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					print("Found file: " + file_name)
					var It = load(g + "/" + file_name)
					Items.append(It)
				
				file_name = dir.get_next()
				
	var Menu = $"VBoxContainer/PanelContainer2/MenuBar/Add Item" as PopupMenu
	while Menu.item_count > 0:
		Menu.remove_item(0)
	for g in Items.size():
		#Menu.add_item(Items[g].ItemName, g)
		Menu.add_icon_item(Items[g].ItemIcon ,Items[g].ItemName, g)
	
func _exit_tree() -> void:
	Captains.clear()
	Items.clear()
	for g in $VBoxContainer/PanelContainer3/VBoxContainer2/VBoxContainer.get_children():
		g.free()
	for g in ItemGrid.get_children():
		g.free()
		
func SetCaptain(C : Captain) -> void:
	
	CurrentlySelectedCap = C
	CaptainName.text = C.CaptainName
	CaptainDesc.text = C.CaptainBio
	CaptainProtrait.texture = C.CaptainPortrait
	ShipIcon.texture = C.ShipIcon
	$VBoxContainer/PanelContainer5/VBoxContainer/StartingFunds.value = C.ProvidingFunds
	print(C.ProvidingFunds)
	
	for g in $VBoxContainer/PanelContainer3/VBoxContainer2/VBoxContainer.get_children():
		g.free()
	for g in C.CaptainStats:
		var newStatUI = StatScene.instantiate() as CapCrStatSlider
		newStatUI._SetData(g)
		newStatUI.connect("StatChanged", SaveCurrentCap)
		if (g.StatName == STAT_CONST.STATS.INVENTORY_SPACE):
			newStatUI.connect("StatChanged", InventorySizeChanged)
		$VBoxContainer/PanelContainer3/VBoxContainer2/VBoxContainer.add_child(newStatUI)
		
	UpdateInventoryBoxes()
	
	
	
func _on_chaptain_select_index_pressed(index: int) -> void:
	SetCaptain(Captains[index])

func SaveCurrentCap() -> void:
	ResourceSaver.save(CurrentlySelectedCap, CurrentlySelectedCap.resource_path)

func InventorySizeChanged() -> void:
	UpdateInventoryBoxes()

func UpdateInventoryBoxes() -> void:

	
	for g in ItemGrid.get_children():
		g.free()
	for g in CurrentlySelectedCap.GetStatBaseValue(STAT_CONST.STATS.INVENTORY_SPACE):
		var ItemBox = ItemBoxScene.instantiate() as Inventory_Box
		ItemBox.connect("ItemSelected", ItemSelected)
		ItemGrid.add_child(ItemBox)
	
	for g in $VBoxContainer/PanelContainer3/VBoxContainer2/VBoxContainer.get_children():
		var sl = g as CapCrStatSlider
		sl.ResetItemStat()
	
	for g in CurrentlySelectedCap.StartingItems:
		AddItem(g)
	
	var FuelCap = FindSliderWithStat(STAT_CONST.STATS.FUEL_TANK).GetStatValue()  
	var FuelEf = FindSliderWithStat(STAT_CONST.STATS.FUEL_EFFICIENCY).GetStatValue()
	var W =  FindSliderWithStat(STAT_CONST.STATS.WEIGHT).GetStatValue()
	var Thrust = FindSliderWithStat(STAT_CONST.STATS.THRUST).GetStatValue()
	var ShipRange = roundi(FuelCap * (FuelEf - (W / 40)))
	var ShipSpeed = roundi((Thrust * 1000) / W)
	var RefuelTime = FuelCap / 0.5 / 60
	$VBoxContainer/PanelContainer3/VBoxContainer2/Label.text = "Ship Range : {0} km, Ship Sped : {1} km/h, Aprox Refuel Time : {2}h".format([var_to_str(ShipRange), ShipSpeed, RefuelTime])
	
	
	$VBoxContainer/PanelContainer4/VBoxContainer/Label.text = "Select Item Above To Show Stats"
	SelectedBox = null
	
var SelectedBox : Inventory_Box

func ItemSelected(It : Inventory_Box) -> void:
	SelectedBox = It
	$VBoxContainer/PanelContainer4/VBoxContainer/Label.text = "{0}\n{1}".format([It._ContainedItem.ItemName, It._ContainedItem.GetItemDesc()])

func _on_remove_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem()):
				CurrentlySelectedCap.StartingItems.remove_at(g)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

func _on_move_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem() and g >= ItemGrid.get_children().find(SelectedBox)):
				var it = CurrentlySelectedCap.StartingItems[g]
				CurrentlySelectedCap.StartingItems.remove_at(g)
				CurrentlySelectedCap.StartingItems.push_front(it)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

func _on_upgrade_item_pressed() -> void:
	if (SelectedBox != null):
		for g in CurrentlySelectedCap.StartingItems.size():
			if (CurrentlySelectedCap.StartingItems[g] == SelectedBox.GetContainedItem() and g >= ItemGrid.get_children().find(SelectedBox)):
				var it = CurrentlySelectedCap.StartingItems[g]
				if (it is ShipPart):
					CurrentlySelectedCap.StartingItems.remove_at(g)
					CurrentlySelectedCap.StartingItems.append(it.UpgradeVersion)
					#CurrentlySelectedCap.StartingItems.push_front(it)
				break
	SaveCurrentCap()
	UpdateInventoryBoxes()

func _on_item_select_index_pressed(index: int) -> void:
	CurrentlySelectedCap.StartingItems.append(Items[index])
	SaveCurrentCap()
	UpdateInventoryBoxes()

func _on_cap_bio_text_changed() -> void:
	var NewLine = CaptainDesc.text
	print("Changed {0}'s bio and saved to file {1}".format([CurrentlySelectedCap.CaptainBio, CurrentlySelectedCap.resource_path]))
	CurrentlySelectedCap.CaptainBio = NewLine
	ResourceSaver.save(CurrentlySelectedCap, CurrentlySelectedCap.resource_path)
func _on_cap_name_text_changed() -> void:
	var NewLine = CaptainName.text
	print("Changed {0}'s name to {1} and saved to file {2}".format([CurrentlySelectedCap.CaptainName, NewLine, CurrentlySelectedCap.resource_path]))
	CurrentlySelectedCap.CaptainName = NewLine
	ResourceSaver.save(CurrentlySelectedCap, CurrentlySelectedCap.resource_path)


# ITEMS
func AddItem(It : Item) -> void:
	var boxes = ItemGrid.get_children()
	var Empty : Inventory_Box = null

	for g in boxes:
		if (g.IsEmpty()):
			if (Empty == null):
				Empty = g
			continue
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			g.UpdateAmm(1)
			break

	if (Empty != null):
		Empty.RegisterItem(It)
		Empty.UpdateAmm(1)
	
	if (!ShowItemStats):
		return
	if (It is ShipPart):
		print(It.resource_name + " is ship part")
		var up = It.Upgrades
		for g : ShipPartUpgrade in up:
			FindSliderWithStat(g.UpgradeName).AddToItemStat(g.UpgradeAmmount, g.PenaltyAmmount)

			
func FindSliderWithStat(St : STAT_CONST.STATS) -> CapCrStatSlider:
	for g in $VBoxContainer/PanelContainer3/VBoxContainer2/VBoxContainer.get_children():
		var sl = g as CapCrStatSlider
		if (sl.CurrentStat.StatName == St):
			print("Fount slider for stat" + STAT_CONST.STATS.keys()[St])
			return g
	return null
	
func _on_change_pic_pressed() -> void:
	var fd = EditorFileDialog.new()
	#fd.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	fd.access = EditorFileDialog.ACCESS_RESOURCES
	EditorInterface.get_base_control().add_child(fd)
	fd.connect("file_selected", NewPicSelected)
	fd.popup_file_dialog()
	#get_parent().add_child(fd)
	#var d = await fd.file_selected
	

func NewPicSelected(NewPic) -> void:
	CurrentlySelectedCap.CaptainPortrait = load(NewPic)
	SaveCurrentCap()
	CaptainProtrait.texture = CurrentlySelectedCap.CaptainPortrait


func _on_change_ship_icon_pressed() -> void:
	var fd = EditorFileDialog.new()
	#fd.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	fd.access = EditorFileDialog.ACCESS_RESOURCES
	EditorInterface.get_base_control().add_child(fd)
	fd.connect("file_selected", NewShipPicSelected)
	fd.popup_file_dialog()
	#get_parent().add_child(fd)
	#var d = await fd.file_selected

func NewShipPicSelected(NewPic) -> void:
	CurrentlySelectedCap.ShipIcon = load(NewPic)
	SaveCurrentCap()
	ShipIcon.texture = CurrentlySelectedCap.ShipIcon


func _on_show_it_stats_toggled(toggled_on: bool) -> void:
	ShowItemStats = toggled_on
	UpdateInventoryBoxes()


func _on_starting_funds_value_changed(value: float) -> void:
	CurrentlySelectedCap.ProvidingFunds = value
	SaveCurrentCap()
	print("StartingFundsUpdated " + var_to_str(value))
