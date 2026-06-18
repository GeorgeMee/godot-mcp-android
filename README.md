# Godot MCP Android

Godot MCP Android is an editor plugin experiment for exposing selected Godot editor operations to AI coding agents running in Termux or on a PC.

Initial transports:

- HTTP JSON-RPC on `127.0.0.1:8765`
- `GET /health`
- `POST /rpc`
- WebSocket JSON-RPC on `ws://127.0.0.1:8766`

The first implementation intentionally keeps the transports small so they can run inside the Android editor without native extensions.

## Layout

```text
addons/godot_mcp_android/
  plugin.cfg
  plugin.gd
  scripts/
    server/
      mcp_http_server.gd
      mcp_websocket_server.gd
    protocol/
      mcp_dispatcher.gd
      mcp_response.gd
      mcp_tool.gd
      mcp_tool_registry.gd
    tools/
      scene/
        add_node_tool.gd
        get_scene_tree_tool.gd
        save_scene_tool.gd
        set_node_property_tool.gd
      system/
        ping_tool.gd
```

Transports only parse and serialize messages. `protocol/` owns JSON-RPC and tool registration. Individual editor capabilities live under `tools/`.

## MCP Methods

- `initialize`
- `tools/list`
- `tools/call`

Current tools:

- `ping`
- `get_scene_tree`
- `add_node`
- `set_node_property`
- `save_scene`

## Quick Check

After opening this project in Godot, the plugin starts automatically.

```bash
curl http://127.0.0.1:8765/health
```

List tools:

```bash
curl -s http://127.0.0.1:8765/rpc \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

Call a tool:

```bash
curl -s http://127.0.0.1:8765/rpc \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}'
```

WebSocket:

```bash
websocat ws://127.0.0.1:8766
```

Then send:

```json
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
```

## Next Steps

- Add allowlist and token-based access before exposing anything beyond localhost.
- Expand editor tools for resources, scene file loading, script editing, and play/debug output.
