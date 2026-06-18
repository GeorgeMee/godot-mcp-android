@tool
extends MCPTool

const DEFAULT_MAX_LINES := 120


func get_name() -> String:
	return "get_editor_log"


func get_description() -> String:
	return "Return recent lines from the Godot user log file when available."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"max_lines": {"type": "number", "description": "Maximum number of recent lines to return."},
		},
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var max_lines := int(arguments.get("max_lines", DEFAULT_MAX_LINES))
	if max_lines <= 0:
		max_lines = DEFAULT_MAX_LINES

	var log_path := _find_latest_log_path()
	if log_path == "":
		return {
			"ok": false,
			"error": "no Godot log file found under user://logs",
			"user_data_dir": OS.get_user_data_dir(),
		}

	var file := FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return tool_error("failed to open log file: %s" % error_string(FileAccess.get_open_error()))

	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line()
		lines.append(line)
		if lines.size() > max_lines:
			lines.pop_front()
	file.close()

	return {
		"ok": true,
		"path": log_path,
		"lines": lines,
	}


func _find_latest_log_path() -> String:
	var logs_dir := "user://logs"
	var dir := DirAccess.open(logs_dir)
	if dir == null:
		return ""

	var latest_path := ""
	var latest_modified := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.get_extension().to_lower() == "log":
			var path := logs_dir.path_join(name)
			var modified := FileAccess.get_modified_time(path)
			if modified >= latest_modified:
				latest_modified = modified
				latest_path = path
		name = dir.get_next()
	dir.list_dir_end()
	return latest_path
