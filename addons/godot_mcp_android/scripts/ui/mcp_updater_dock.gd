@tool
class_name MCPUpdaterDock
extends VBoxContainer

const PLUGIN_DIR := "addons/godot_mcp_android"
const LATEST_RELEASE_URL := "https://api.github.com/repos/GeorgeMee/godot-mcp-android/releases/latest"
const SETTING_BIND_HOST := "godot_mcp_android/bind_host"
const SETTING_HTTP_PORT := "godot_mcp_android/http_port"
const SETTING_WS_PORT := "godot_mcp_android/ws_port"
const DEFAULT_BIND_HOST := "127.0.0.1"
const DEFAULT_HTTP_PORT := 8765
const DEFAULT_WS_PORT := 8766

signal settings_changed(host: String, http_port: int, ws_port: int)
signal focus_restored()

var _check_button: Button
var _install_button: Button
var _status_label: Label
var _release_request: HTTPRequest
var _download_request: HTTPRequest
var _latest_version := ""
var _latest_zip_url := ""
var _download_path := ""
var _copy_url_button: Button
var _manual_install_button: Button
var _file_dialog: FileDialog
var _host_input: LineEdit
var _http_port_spin: SpinBox
var _ws_port_spin: SpinBox
var _apply_button: Button


func _init() -> void:
	name = "Godot MCP"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	custom_minimum_size = Vector2(280, 0)

	var title := Label.new()
	title.text = "Godot MCP Android"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	var version := Label.new()
	version.text = "Installed: %s" % _get_installed_version()
	add_child(version)

	_check_button = Button.new()
	_check_button.text = "Check Plugin Update"
	_check_button.pressed.connect(_on_check_update_pressed)
	add_child(_check_button)

	_install_button = Button.new()
	_install_button.text = "Install Latest Release"
	_install_button.disabled = true
	_install_button.pressed.connect(_on_install_update_pressed)
	add_child(_install_button)

	_copy_url_button = Button.new()
	_copy_url_button.text = "Copy Download URL"
	_copy_url_button.disabled = true
	_copy_url_button.pressed.connect(_on_copy_url_pressed)
	add_child(_copy_url_button)

	_manual_install_button = Button.new()
	_manual_install_button.text = "Manual Install..."
	_manual_install_button.pressed.connect(_on_manual_install_pressed)
	add_child(_manual_install_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Ready."
	add_child(_status_label)

	_release_request = HTTPRequest.new()
	_release_request.request_completed.connect(_on_release_request_completed)
	add_child(_release_request)

	_download_request = HTTPRequest.new()
	_download_request.request_completed.connect(_on_download_request_completed)
	add_child(_download_request)

_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.title = "Select downloaded plugin zip"
	_file_dialog.add_filter("*.zip", "ZIP Archive")
	_file_dialog.file_selected.connect(_on_zip_file_selected)
	add_child(_file_dialog)

	var separator := HSeparator.new()
	add_child(separator)

	var settings_title := Label.new()
	settings_title.text = "Server Settings"
	settings_title.add_theme_font_size_override("font_size", 14)
	add_child(settings_title)

	var host_row := HBoxContainer.new()
	var host_label := Label.new()
	host_label.text = "Host:"
	host_label.custom_minimum_size = Vector2(80, 0)
	host_row.add_child(host_label)
	_host_input = LineEdit.new()
	_host_input.text = ProjectSettings.get_setting(SETTING_BIND_HOST, DEFAULT_BIND_HOST)
	_host_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_row.add_child(_host_input)
	add_child(host_row)

	var http_port_row := HBoxContainer.new()
	var http_port_label := Label.new()
	http_port_label.text = "HTTP Port:"
	http_port_label.custom_minimum_size = Vector2(80, 0)
	http_port_row.add_child(http_port_label)
	_http_port_spin = SpinBox.new()
	_http_port_spin.min_value = 1
	_http_port_spin.max_value = 65535
	_http_port_spin.step = 1
	_http_port_spin.value = ProjectSettings.get_setting(SETTING_HTTP_PORT, DEFAULT_HTTP_PORT)
	_http_port_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	http_port_row.add_child(_http_port_spin)
	add_child(http_port_row)

	var ws_port_row := HBoxContainer.new()
	var ws_port_label := Label.new()
	ws_port_label.text = "WS Port:"
	ws_port_label.custom_minimum_size = Vector2(80, 0)
	ws_port_row.add_child(ws_port_label)
	_ws_port_spin = SpinBox.new()
	_ws_port_spin.min_value = 1
	_ws_port_spin.max_value = 65535
	_ws_port_spin.step = 1
	_ws_port_spin.value = ProjectSettings.get_setting(SETTING_WS_PORT, DEFAULT_WS_PORT)
	_ws_port_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ws_port_row.add_child(_ws_port_spin)
	add_child(ws_port_row)

	_apply_button = Button.new()
	_apply_button.text = "Apply & Restart Servers"
	_apply_button.pressed.connect(_on_apply_settings_pressed)
	add_child(_apply_button)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_restored.emit()


func _on_check_update_pressed() -> void:
	_set_busy(true)
	_install_button.disabled = true
	_latest_version = ""
	_latest_zip_url = ""
	_set_status("Checking latest GitHub release...")

	var error := _release_request.request(
		LATEST_RELEASE_URL,
		[
			"Accept: application/vnd.github+json",
			"User-Agent: Godot-MCP-Android",
		]
	)
	if error != OK:
		_set_busy(false)
		_set_status("Failed to start release request: %s" % error_string(error))


func _on_install_update_pressed() -> void:
	if _latest_zip_url == "":
		_set_status("No release zip is available.")
		return

	_set_busy(true)
	_install_button.disabled = true
	_download_path = "user://godot_mcp_android_latest.zip"
	_download_request.download_file = _download_path
	_set_status("Downloading %s..." % _latest_version)

	var error := _download_request.request(
		_latest_zip_url,
		[
			"Accept: application/octet-stream",
			"User-Agent: Godot-MCP-Android",
		]
	)
	if error != OK:
		_set_busy(false)
		_set_status("Failed to start download: %s" % error_string(error))


func _on_release_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_set_busy(false)
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_status("Release request failed: %s (code %d)" % [_http_result_name(result), result])
		return
	if response_code != 200:
		_set_status("GitHub release request returned HTTP %d." % response_code)
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("GitHub release response was not a JSON object.")
		return

	_latest_version = String(parsed.get("tag_name", ""))
	_latest_zip_url = _find_release_zip_url(parsed)
	if _latest_zip_url == "":
		_set_status("Latest release has no plugin zip asset.")
		return

	_install_button.disabled = false
	_copy_url_button.disabled = false
	var installed := _get_installed_version()
	if installed == _latest_version:
		_set_status("Latest release is already installed: %s" % installed)
	else:
		_set_status("Latest release available: %s. Tap install to update." % _latest_version)


func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_set_busy(false)
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_status("Download failed: %s (code %d)" % [_http_result_name(result), result])
		return
	if response_code < 200 or response_code >= 300:
		_set_status("Download returned HTTP %d." % response_code)
		return

	var error := _install_zip(_download_path)
	if error != OK:
		_set_status("Install failed: %s" % error_string(error))
		return

	_set_status("Update installed. Restart Godot Editor to reload the plugin.")


func _on_apply_settings_pressed() -> void:
	var host := _host_input.text.strip_edges()
	if host == "":
		_set_status("Host cannot be empty.")
		return

	var http_port := int(_http_port_spin.value)
	var ws_port := int(_ws_port_spin.value)

	ProjectSettings.set_setting(SETTING_BIND_HOST, host)
	ProjectSettings.set_setting(SETTING_HTTP_PORT, http_port)
	ProjectSettings.set_setting(SETTING_WS_PORT, ws_port)
	ProjectSettings.save()

	settings_changed.emit(host, http_port, ws_port)
	_set_status("Settings applied. Servers restarting on %s (HTTP:%d, WS:%d)..." % [host, http_port, ws_port])


func _find_release_zip_url(release_data: Dictionary) -> String:
	var assets = release_data.get("assets", [])
	if typeof(assets) != TYPE_ARRAY:
		return ""

	for asset in assets:
		if typeof(asset) != TYPE_DICTIONARY:
			continue
		var name := String(asset.get("name", "")).to_lower()
		if name.ends_with(".zip") and name.contains("godot_mcp_android"):
			return String(asset.get("browser_download_url", ""))

	return ""


func _install_zip(zip_path: String) -> Error:
	var reader := ZIPReader.new()
	var error := reader.open(zip_path)
	if error != OK:
		return error

	var project_root := ProjectSettings.globalize_path("res://")
	for file_path in reader.get_files():
		if not String(file_path).begins_with("%s/" % PLUGIN_DIR):
			continue
		if String(file_path).ends_with("/"):
			continue

		var bytes := reader.read_file(file_path)
		var target_path := project_root.path_join(file_path)
		error = _ensure_parent_dir(target_path)
		if error != OK:
			reader.close()
			return error

		var file := FileAccess.open(target_path, FileAccess.WRITE)
		if file == null:
			reader.close()
			return FileAccess.get_open_error()
		file.store_buffer(bytes)
		file.close()

	reader.close()
	return OK


func _ensure_parent_dir(file_path: String) -> Error:
	var parent_dir := file_path.get_base_dir()
	if DirAccess.dir_exists_absolute(parent_dir):
		return OK
	return DirAccess.make_dir_recursive_absolute(parent_dir)


func _get_installed_version() -> String:
	var config := ConfigFile.new()
	var error := config.load("res://addons/godot_mcp_android/plugin.cfg")
	if error != OK:
		return "unknown"
	return String(config.get_value("plugin", "version", "unknown"))


func _on_copy_url_pressed() -> void:
	if _latest_zip_url.is_empty():
		return
	DisplayServer.clipboard_set(_latest_zip_url)
	_set_status("Download URL copied to clipboard!")


func _on_manual_install_pressed() -> void:
	_file_dialog.popup_centered(Vector2i(600, 400))


func _on_zip_file_selected(path: String) -> void:
	var error := _install_zip(path)
	if error != OK:
		_set_status("Install failed: %s" % error_string(error))
		return
	_set_status("Plugin installed from file. Restart Godot Editor to reload the plugin.")


static func _http_result_name(result: int) -> String:
	match result:
		HTTPRequest.RESULT_SUCCESS:
			return "SUCCESS"
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "CHUNKED_BODY_SIZE_MISMATCH"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "CANT_CONNECT"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "CANT_RESOLVE"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "CONNECTION_ERROR"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS_HANDSHAKE_ERROR"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "NO_RESPONSE"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "BODY_SIZE_LIMIT_EXCEEDED"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "REQUEST_FAILED"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "DOWNLOAD_FILE_CANT_OPEN"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "DOWNLOAD_FILE_WRITE_ERROR"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "REDIRECT_LIMIT_REACHED"
		HTTPRequest.RESULT_TIMEOUT:
			return "TIMEOUT"
	return "UNKNOWN(%d)" % result


func _set_busy(is_busy: bool) -> void:
	_check_button.disabled = is_busy
	if is_busy:
		_install_button.disabled = true


func _set_status(message: String) -> void:
	_status_label.text = message