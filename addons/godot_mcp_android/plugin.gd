@tool
extends EditorPlugin

const MCPHttpServer := preload("res://addons/godot_mcp_android/scripts/mcp_http_server.gd")

var _server: MCPHttpServer


func _enter_tree() -> void:
	_server = MCPHttpServer.new(get_editor_interface())
	var error := _server.start()
	if error != OK:
		push_error("Godot MCP Android failed to start HTTP JSON-RPC server: %s" % error_string(error))
		return

	set_process(true)
	print("Godot MCP Android listening on %s:%d" % [_server.bind_host, _server.port])


func _exit_tree() -> void:
	set_process(false)
	if _server != null:
		_server.stop()
		_server = null


func _process(_delta: float) -> void:
	if _server != null:
		_server.poll()
