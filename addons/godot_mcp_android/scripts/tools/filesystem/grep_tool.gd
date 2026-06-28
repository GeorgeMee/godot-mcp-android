@tool
extends MCPTool


func get_name() -> String:
	return "grep"


func get_description() -> String:
	return "Search file contents in the project using a regex pattern."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"pattern": {"type": "string", "description": "Regex pattern to search for."},
			"path": {"type": "string", "description": "Project-relative path or res:// path to search in. Defaults to res://."},
			"include": {"type": "string", "description": "File glob pattern to filter, e.g. '*.gd' or '*.tscn'."},
			"max_results": {"type": "number", "description": "Maximum number of matches to return."},
		},
		"required": ["pattern"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var pattern := String(arguments.get("pattern", ""))
	if pattern == "":
		return tool_error("pattern is required")

	var search_path := String(arguments.get("path", ""))
	if search_path != "" and not is_safe_project_path(search_path):
		return tool_error("path must stay inside res://")

	var include_pattern := String(arguments.get("include", ""))
	var max_results := int(arguments.get("max_results", 200))
	if max_results <= 0:
		max_results = 200

	var reg := RegEx.new()
	var error := reg.compile(pattern)
	if error != OK:
		return tool_error("invalid regex pattern: %s" % pattern)

	var root := "res://"
	if search_path != "":
		var normalized := normalize_project_path(search_path)
		if normalized != "." and normalized != "":
			root = "res://%s" % normalized

	var matches: Array = []
	_search_dir(root, reg, include_pattern, max_results, matches)

	return {
		"ok": true,
		"pattern": pattern,
		"matches": matches,
		"truncated": matches.size() >= max_results,
	}


func _search_dir(dir_path: String, regex: RegEx, include_pattern: String, max_results: int, matches: Array) -> void:
	if matches.size() >= max_results:
		return

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if matches.size() >= max_results:
			break
		if name == "." or name == "..":
			name = dir.get_next()
			continue

		var child_path := dir_path.path_join(name)
		if dir.current_is_dir():
			_search_dir(child_path, regex, include_pattern, max_results, matches)
		else:
			if include_pattern != "":
				if not name.match(include_pattern):
					name = dir.get_next()
					continue

			var file := FileAccess.open(child_path, FileAccess.READ)
			if file == null:
				name = dir.get_next()
				continue

			var line_number := 1
			while not file.eof_reached():
				if matches.size() >= max_results:
					break
				var line := file.get_line()
				var result := regex.search(line)
				if result != null:
					matches.append({
						"path": child_path,
						"line": line_number,
						"text": line,
					})
				line_number += 1
			file.close()

		name = dir.get_next()

	dir.list_dir_end()