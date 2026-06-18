@tool
extends EditorPlugin

const MCPHttpServer := preload("res://addons/godot_mcp_android/scripts/server/mcp_http_server.gd")
const MCPWebSocketServer := preload("res://addons/godot_mcp_android/scripts/server/mcp_websocket_server.gd")

var _http_server: MCPHttpServer
var _websocket_server: MCPWebSocketServer


func _enter_tree() -> void:
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

	set_process(true)


func _exit_tree() -> void:
	set_process(false)
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
