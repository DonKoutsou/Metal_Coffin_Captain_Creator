extends RefCounted

class_name CptHelper

static func get_target_path_from_remap(remap_file_path: String) -> String:
	var config = ConfigFile.new()
	var err = config.load(remap_file_path)
	
	if err == OK:
		# Check if the [remap] section has the "path" property
		if config.has_section_key("remap", "path"):
			var internal_binary_path = config.get_value("remap", "path")
			return internal_binary_path # Returns something like "res://.godot/exported/..."
	
	print("Failed to parse remap file: ", remap_file_path)
	return ""

static func GetFilePathFromUID(projectPath : String ,UID : String) -> String:
	# 1. Point to the unpacked .godot cache folder
	var virtual_cache_path = projectPath + "/.godot/uid_cache.bin"
	
	if not FileAccess.file_exists(virtual_cache_path):
		print("Warning: uid_cache.bin not found inside the mounted PCK layout.")
		return ""
		
	print("Parsing binary uid_cache.bin to reconstitute individual .uid files...")
	
	var file = FileAccess.open(virtual_cache_path, FileAccess.READ)
	if not file:
		print("Failed to open binary cache file.")
		return ""
	
	var target_uid: int = ResourceUID.text_to_id(UID)

	if target_uid == ResourceUID.INVALID_ID:
		print("Invalid UID: ", UID)
		return ""
	
	# 2. Parse the Godot 4 central UID binary format
	# Format Layout: [Int32: Magic/Entry Count] followed by pairs of [Int64: ID] and [String: Path]
	var entry_count = file.get_32()
	
	for i in range(entry_count):
		if file.get_position() >= file.get_length():
			break
			
		var uid_int64 : int = file.get_64()    # The unique numeric integer ID
		
		var path_length : int = file.get_32()
		
		#print(
			#"Entry ", i,
			#" UID=", uid_int64,
			#" length=", path_length,
			#" position=", file.get_position()
		#)
		
		if path_length < 0 or path_length > file.get_length() - file.get_position():
			return ""
		
		var path_bytes: PackedByteArray = file.get_buffer(path_length)
		
		if uid_int64 == target_uid:
			var virtual_path := path_bytes.get_string_from_utf8()

			print("FOUND!")
			print("UID: ", UID)
			print("Path: ", virtual_path)
			
			return virtual_path
			
	return ""
	
