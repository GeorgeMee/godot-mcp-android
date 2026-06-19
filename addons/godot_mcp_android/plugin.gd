@tool
extends EditorPlugin

const MCPHttpServer := preload("res://addons/godot_mcp_android/scripts/server/mcp_http_server.gd")
const MCPWebSocketServer := preload("res://addons/godot_mcp_android/scripts/server/mcp_websocket_server.gd")
const MCPUpdaterDock := preload("res://addons/godot_mcp_android/scripts/ui/mcp_updater_dock.gd")

var _http_server: MCPHttpServer
var _websocket_server: MCPWebSocketServer
var _updater_dock: MCPUpdaterDock


func _enter_tree() -> void:
	_updater_dock = MCPUpdaterDock.new()
	_updater_dock.settings_changed.connect(_on_settings_changed)
	_updater_dock.focus_restored.connect(_on_focus_restored)
	add_control_to_dock(DOCK_SLOT_LEFT_BL, _updater_dock)

	_start_servers()
	set_process(true)


func _start_servers() -> void:
	if _http_server != null:
		_http_server = null
	if _websocket_server != null:
		_websocket_server = null

	_http_server = MCPHttpServer.new(get_editor_interface())
	var error := _http_server.start()
	if error != OK:
		push_error("Godot MCP Android failed to start HTTP JSON-RPC server: %s" % error_string(error))
	else:
		print("Godot MCP Android HTTP JSON-RPC listening on %s:%d" % [_http_server.bind_host, _http_server.port])

	_websocket_server = MCPWebSocketServer.new(get_editor_interface())
	error = _websocket_server.start()
	if error != OK:
		push_error("Godot MCP Android failed to start WebSocket JSON-RPC server: %s" % error_string(error))
	else:
		print("Godot MCP Android WebSocket JSON-RPC listening on ws://%s:%d" % [_websocket_server.bind_host, _websocket_server.port])


func _on_settings_changed(_host: String, _http_port: int, _ws_port: int) -> void:
	_restart_servers()


func _on_focus_restored() -> void:
	_restart_servers()


func _restart_servers() -> void:
	_http_server.stop()
	_websocket_server.stop()
	_http_server = null
	_websocket_server = null
	_start_servers()


func _exit_tree() -> void:
	set_process(false)
	if _updater_dock != null:
		remove_control_from_docks(_updater_dock)
		_updater_dock.queue_free()
		_updater_dock = null

	if _websocket_server != null:
		_websocket_server.stop()
		_websocket_server = null
	if _http_server != null:
		_http_server.stop()
		_http_server = null


func _process(_delta: float) -> void:
	if _http_server != null:
		_http_server.poll()
	if _websocket_server != null:
		_websocket_server.poll()
