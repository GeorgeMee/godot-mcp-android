@tool
extends MCPTool


func get_name() -> String:
	return "get_resource_uid"


func get_description() -> String:
	return "Return the Godot ResourceUID for a project resource path."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path."},
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
	if not FileAccess.file_exists(resource_path):
		return tool_error("file not found: %s" % resource_path)

	var uid: int = ResourceLoader.get_resource_uid(resource_path)
	return {
		"ok": uid != ResourceUID.INVALID_ID,
		"path": resource_path,
		"uid": uid,
		"uid_text": "" if uid == ResourceUID.INVALID_ID else ResourceUID.id_to_text(uid),
	}
