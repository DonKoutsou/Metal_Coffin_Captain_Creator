extends PanelContainer

class_name Main

@export var CptCrator : PackedScene
@export var resPicker : ResourcePicker
@export var BasePackPicker : ResourcePicker
#@export var ModPackPicker : ResourcePicker

var execPath

static var dirs : SaveDirs

const TRANSLATIONS : PackedStringArray = [
	"Localisations/LOC - Cards.english.translation",
	"Localisations/LOC - Cards.greek.translation",
	"Localisations/LOC - FlightManual.english.translation",
	"Localisations/LOC - Stat.english.translation",
	"Localisations/LOC - Tutorial.english.translation",
]

func _ready() -> void:
	execPath = OS.get_executable_path()
	execPath = execPath.replace(execPath.get_file(), "")
	
	if not FileAccess.file_exists(execPath + "SavedDir.tres"):
		ResourceSaver.save(SaveDirs.new(), execPath + "SavedDir.tres")
	
	dirs = ResourceLoader.load(execPath + "SavedDir.tres")
	
	BasePackPicker.SetFile(dirs.BaseDataDir)
	#ModPackPicker.SetFile(dirs.ModPackDir)
	resPicker.SetFile(dirs.ModDir)

func _on_ready_pressed() -> void:
	if (dirs.ModDir.is_empty()):
		print("No dir selected")
		return
	
	if (dirs.BaseDataDir.is_empty()):
		print("No Mod Pack dir selected")
		return
	
	#if (dirs.ModPackDir.is_empty()):
		#print("No Mod Pack dir selected")
		#return
	#LoadResources()
	
	ProjectSettings.load_resource_pack(dirs.BaseDataDir)
	#ProjectSettings.load_resource_pack(dirs.ModPackDir)
	
	
	DispositionManagerSc.DispRewards = load(dirs.ModDir + "/Configs/DispositionRewards.tres")
	#await get_tree().process_frame
	
	var editor_domain := TranslationServer.get_or_add_domain(&"")
	for locale: String in TRANSLATIONS:
		editor_domain.add_translation(load(dirs.ModDir + "/" +locale))
	editor_domain.set_locale_override("english")

	
	get_child(0).queue_free()
	var cpt : CaptainCreatorUI = CptCrator.instantiate()
	cpt.projPath = dirs.ModDir
	cpt.startingDir = dirs.ModDir + "/Resources"
	add_child(cpt)

func LoadResources() -> void:
	var pck = PCKPacker.new()
	
	var DirsToExplore :Array[String] = [dirs.ModDir + "/Resources/Cards", dirs.ModDir + "/Resources/Items"]
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
					print("Found file: " + g + "/" + file_name)
					if (file_name.ends_with(".tres")):
						#var file = ResourceLoader.load(g + "/" + file_name)
						var targetPath = g.replace(dirs.ModDir, "res:/") + "/" + file_name
						pck.add_file(targetPath ,g + "/" + file_name)
						print(targetPath)
				
				file_name = dir.get_next()
	pck.flush(true)
	ResourceSaver.save(pck, dirs.ModDir + "/resources.pck")
	ProjectSettings.load_resource_pack(dirs.ModDir + "/resources.pck")
	DirAccess.remove_absolute(dirs.ModDir + "/resources.pck")
	

func _on_resource_picker_changed(t: String) -> void:
	if (t.is_empty()):
		return
	dirs.ModDir = t
	ResourceSaver.save(dirs, execPath + "SavedDir.tres")
	print("Captain Directory changed to {0}".format([t]))


func _on_mod_pack_changed(t: String) -> void:
	if (t.is_empty()):
		return
	dirs.ModPackDir = t
	ResourceSaver.save(dirs, execPath + "SavedDir.tres")


func _on_base_pack_changed(t: String) -> void:
	if (t.is_empty()):
		return
	dirs.BaseDataDir = t
	ResourceSaver.save(dirs, execPath + "SavedDir.tres")
