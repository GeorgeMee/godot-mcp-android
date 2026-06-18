# Godot MCP Android

Godot MCP Android is an editor plugin experiment for exposing selected Godot editor operations to AI coding agents running in Termux or on a PC.

Initial transport:

- HTTP JSON-RPC on `127.0.0.1:8765`
- `GET /health`
- `POST /rpc`

The first implementation intentionally keeps the transport small so it can run inside the Android editor without native extensions.

## Layout

```text
addons/godot_mcp_android/
  plugin.cfg
  plugin.gd
  scripts/
    mcp_http_server.gd
    mcp_dispatcher.gd
```

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

## Next Steps

- Add WebSocket transport using the same dispatcher.
- Add allowlist and token-based access before exposing anything beyond localhost.
- Expand editor tools for resources, scene file loading, script editing, and play/debug output.
