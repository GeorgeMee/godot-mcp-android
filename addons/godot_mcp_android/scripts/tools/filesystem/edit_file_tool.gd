@tool
extends MCPTool


func get_name() -> String:
	return "edit_file"


func get_description() -> String:
	return "Find and replace text in a project file by exact string match."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path to the file."},
			"old_string": {"type": "string", "description": "Exact string to find and replace."},
			"new_string": {"type": "string", "description": "Replacement string."},
			"replace_all": {"type": "boolean", "description": "Replace all occurrences. Defaults to replacing only the first."},
		},
		"required": ["path", "old_string", "new_string"],
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

	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return tool_error("failed to open file: %s" % error_string(FileAccess.get_open_error()))

	var content := file.get_as_text()
	file.close()

	var old_string := String(arguments.get("old_string", ""))
	var new_string := String(arguments.get("new_string", ""))
	var replace_all := bool(arguments.get("replace_all", false))

	if old_string == "":
		return tool_error("old_string is required")

	var count := 0
	if replace_all:
		var parts := content.split(old_string)
		count = parts.size() - 1
		content = new_string.join(parts)
	else:
		var index := content.find(old_string)
		if index == -1:
			return tool_error("old_string not found in file")
		content = content.substr(0, index) + new_string + content.substr(index + old_string.length())
		count = 1

	var write_file := FileAccess.open(resource_path, FileAccess.WRITE)
	if write_file == null:
		return tool_error("failed to write file: %s" % error_string(FileAccess.get_open_error()))

	write_file.store_string(content)
	write_file.close()

	if editor_interface != null:
		editor_interface.get_resource_filesystem().update_file(resource_path)

	return {
		"ok": true,
		"path": resource_path,
		"replacements": count,
	}