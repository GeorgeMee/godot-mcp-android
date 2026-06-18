@tool
extends MCPTool

const DEFAULT_MAX_BYTES := 200000


func get_name() -> String:
	return "read_file"


func get_description() -> String:
	return "Read a UTF-8 text file from the current project."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path."},
			"max_bytes": {"type": "number", "description": "Maximum bytes to read."},
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

	var max_bytes := int(arguments.get("max_bytes", DEFAULT_MAX_BYTES))
	if max_bytes <= 0:
		max_bytes = DEFAULT_MAX_BYTES

	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return tool_error("failed to open file: %s" % error_string(FileAccess.get_open_error()))

	var total_size := file.get_length()
	var bytes_to_read := mini(total_size, max_bytes)
	var bytes := file.get_buffer(bytes_to_read)
	file.close()

	return {
		"ok": true,
		"path": resource_path,
		"text": bytes.get_string_from_utf8(),
		"bytes_read": bytes_to_read,
		"total_bytes": total_size,
		"truncated": total_size > bytes_to_read,
	}
