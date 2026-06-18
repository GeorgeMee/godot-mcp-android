@tool
extends MCPTool


func get_name() -> String:
	return "validate_resource"


func get_description() -> String:
	return "Validate that a project resource exists, loads, and has valid external resource references."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path."},
			"instantiate_scene": {"type": "boolean", "description": "Instantiate PackedScene resources as part of validation."},
		},
		"required": ["path"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var path := String(arguments.get("path", ""))
	if path == "":
		return tool_error("path is required")
	if not is_safe_project_path(path):
		return tool_error("path must stay inside res://")

	var resource_path := "res://%s" % normalize_project_path(path)
	var issues: Array = []
	if not FileAccess.file_exists(resource_path):
		return {
			"ok": false,
			"path": resource_path,
			"issues": [{"severity": "error", "message": "file not found"}],
		}

	issues.append_array(_validate_external_resource_paths(resource_path))

	var exists := ResourceLoader.exists(resource_path)
	if not exists:
		issues.append({"severity": "error", "message": "ResourceLoader.exists returned false"})

	var resource := ResourceLoader.load(resource_path)
	if resource == null:
		issues.append({"severity": "error", "message": "ResourceLoader.load returned null"})
	else:
		if bool(arguments.get("instantiate_scene", true)) and resource is PackedScene:
			var scene := resource as PackedScene
			var instance: Node = scene.instantiate()
			if instance == null:
				issues.append({"severity": "error", "message": "PackedScene.instantiate returned null"})
			else:
				instance.free()

	var uid: int = ResourceLoader.get_resource_uid(resource_path)
	return {
		"ok": _has_no_errors(issues),
		"path": resource_path,
		"type": "" if resource == null else resource.get_class(),
		"resource_exists": exists,
		"uid_text": "" if uid == ResourceUID.INVALID_ID else ResourceUID.id_to_text(uid),
		"issues": issues,
	}


func _validate_external_resource_paths(resource_path: String) -> Array:
	var extension := resource_path.get_extension().to_lower()
	if extension != "tscn" and extension != "tres":
		return []

	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return [{"severity": "error", "message": "failed to read text resource: %s" % error_string(FileAccess.get_open_error())}]

	var text := file.get_as_text()
	file.close()

	var issues: Array = []
	var regex := RegEx.new()
	var error := regex.compile("path=\"([^\"]+)\"")
	if error != OK:
		return [{"severity": "error", "message": "failed to compile ext_resource path regex"}]

	for result in regex.search_all(text):
		var referenced_path := String(result.get_string(1))
		if not referenced_path.begins_with("res://"):
			continue
		if not ResourceLoader.exists(referenced_path) and not FileAccess.file_exists(referenced_path):
			issues.append({
				"severity": "error",
				"message": "missing external resource path",
				"path": referenced_path,
			})

	return issues


func _has_no_errors(issues: Array) -> bool:
	for issue in issues:
		if typeof(issue) == TYPE_DICTIONARY and String(issue.get("severity", "")) == "error":
			return false
	return true
