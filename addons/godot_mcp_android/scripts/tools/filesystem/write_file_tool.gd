@tool
extends MCPTool


func get_name() -> String:
	return "write_file"


func get_description() -> String:
	return "Write a UTF-8 text file inside the current project."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path."},
			"text": {"type": "string", "description": "File contents to write."},
		},
		"required": ["path", "text"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var path := String(arguments.get("path", ""))
	if path == "":
		return tool_error("path is required")
	if not is_safe_project_path(path):
		return tool_error("path must stay inside res://")

	var normalized := normalize_project_path(path)
	var resource_path := "res://%s" % normalized
	var global_path := globalize_project_path(normalized)
	var parent_dir := global_path.get_base_dir()
	var error := OK
	if not DirAccess.dir_exists_absolute(parent_dir):
		error = DirAccess.make_dir_recursive_absolute(parent_dir)
		if error != OK:
			return tool_error("failed to create parent directory: %s" % error_string(error))

	var file := FileAccess.open(resource_path, FileAccess.WRITE)
	if file == null:
		return tool_error("failed to open file for writing: %s" % error_string(FileAccess.get_open_error()))

	var text := String(arguments.get("text", ""))
	file.store_string(text)
	file.close()

	if editor_interface != null:
		editor_interface.get_resource_filesystem().scan_sources()
		editor_interface.get_resource_filesystem().update_file(resource_path)

	return {
		"ok": true,
		"path": resource_path,
		"bytes_written": text.to_utf8_buffer().size(),
	}
