# CLI Reference – skylight-cli

## Global Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--pid` | `pid_t` | required | Target macOS process ID |
| `--element-index` | `int` | required | 0-based index of element to click |
| `--mode` | `string` | `raw` | Screenshot mode: `raw`, `som`, `grid` |
| `--out` | `path` | `skylight_screenshot.png` | Output file path |
| `--dry-run` | `bool` | `false` | Preview only, no real event |
| `--timeout` | `int` | `15` | Max seconds to wait |
| `--selector` | `string` | `""` | CSS/AX selector for `wait-for-selector` |
| `--window-id` | `int` | `0` | Specific window ID (0 = main window of PID) |
| `--include-tree` | `bool` | `false` | Include full AX tree in screenshot JSON |

---

## Subcommands

### `screenshot`

Captures window content with optional Set-of-Marks overlay.

**Usage:**
```bash
skylight-cli screenshot --pid <PID> [--mode raw|som|grid] [--out <path>] [--dry-run] [--include-tree]
```

**Success JSON (stdout):**
```json
{
  "status": "ok",
  "command": "screenshot",
  "file": "current.png",
  "width": 1920,
  "height": 1080,
  "elements": 12
}
```

**Error JSON (stderr):**
```json
{
  "status": "error",
  "code": "WINDOW_NOT_FOUND",
  "message": "No usable window found for PID 1234"
}
```

**Exit Codes:**
- `0`: Success
- `2`: PID not found or no usable window
- `99`: Accessibility permission missing

**Example:**
```bash
skylight-cli screenshot --pid 1234 --mode som --out survey.png
```

---

### `click`

Performs invisible click on element by index.

**Usage:**
```bash
skylight-cli click --pid <PID> --element-index <N> [--dry-run]
```

**Success JSON (stdout):**
```json
{
  "status": "ok",
  "command": "click",
  "clicked": 14,
  "pos": {"x": 350.5, "y": 520.0},
  "fallback": "AXPress"
}
```
> The `fallback` field is only present if SkyLight was unavailable and AX press or CGEvent was used.

**Error JSON (stderr):**
```json
{
  "status": "error",
  "code": "ELEMENT_OUT_OF_RANGE",
  "message": "Element index 7 >= available 5"
}
```

**Exit Codes:**
- `0`: Success
- `2`: PID not found
- `3`: Element index out of bounds
- `4`: Click rejected or I/O error

**Example:**
```bash
skylight-cli click --pid 1234 --element-index 3
```

---

### `wait-for-selector`

Blocks until an element matching CSS/AX selector appears.

**Usage:**
```bash
skylight-cli wait-for-selector --pid <PID> --selector "<SELECTOR>" [--timeout <seconds>]
```

**Success JSON (stdout):**
```json
{
  "status": "ok",
  "command": "wait-for-selector",
  "found": true,
  "selector": ".btn-start",
  "after": 2.3
}
```

**Timeout JSON (stderr):**
```json
{
  "status": "error",
  "code": "TIMEOUT",
  "message": "Timeout after 15s waiting for '.btn-start'"
}
```

**Exit Codes:**
- `0`: Element found
- `5`: Timeout exceeded

**Example:**
```bash
skylight-cli wait-for-selector --pid 1234 --selector "AXButton:Start" --timeout 30
```

---

### `get-window-state`

Returns geometry and focus state of target window.

**Usage:**
```bash
skylight-cli get-window-state --pid <PID>
```

**Success JSON (stdout):**
```json
{
  "status": "ok",
  "command": "get-window-state",
  "pid": 1234,
  "x": 100,
  "y": 200,
  "width": 800,
  "height": 600,
  "visible": true,
  "focused": false
}
```

**Error JSON (stderr):**
```json
{
  "status": "error",
  "code": "WINDOW_NOT_FOUND",
  "message": "No usable window found for PID 1234"
}
```

**Exit Codes:**
- `0`: Success
- `2`: PID not found or no usable window

**Example:**
```bash
skylight-cli get-window-state --pid 1234
```

---

### `list-elements`

Returns a flat list of all interactive elements in the window.

**Usage:**
```bash
skylight-cli list-elements --pid <PID>
```

**Success JSON (stdout):**
```json
{
  "status": "ok",
  "command": "list-elements",
  "count": 12,
  "elements": [
    {"index": 0, "role": "AXButton", "label": "Submit", "x": 100, "y": 200, "w": 80, "h": 30},
    {"index": 1, "role": "AXTextField", "label": "Email", "x": 100, "y": 240, "w": 200, "h": 30}
  ]
}
```

**Exit Codes:**
- `0`: Success
- `2`: PID not found or no usable window

**Example:**
```bash
skylight-cli list-elements --pid 1234
```

---

## JSON Output Conventions

1. **Success** always includes `"status":"ok"` + command-specific fields.
2. **Error** always includes `"status":"error"`, a machine-readable `"code"`, and a human `"message"`.
3. **Stdout** for data, **stderr** for errors – never mix.
4. **Additional debug info** can appear under `"debug":{}` key (e.g., `"debug":{"ax_count":12,"skylight_loaded":true}`).
5. **Exactly one JSON object per invocation.** No streaming, no multiple documents.
6. **No trailing whitespace or extra newlines** beyond the final `\n`.

---

## Exit Code Summary

| Code | Meaning | Retry Strategy |
|------|---------|----------------|
| 0 | Success | N/A |
| 1 | Internal error | Do not retry; report bug |
| 2 | Bad arguments / window not found | Fix call site; do not retry |
| 3 | Element out of range | Re-screenshot first, then retry once |
| 4 | I/O or click rejection | Fall back to keyboard nav or report |
| 5 | Timeout | Ask LLM to re-plan; page may not have loaded |
| 99 | Accessibility permission missing | User must grant permission; do not retry |

---

## Fallback Behavior

If SkyLight private framework is not available (`dlopen` fails):

1. Tool falls back to `AXUIElementPerformAction(kAXPressAction)` for clicks.
2. If that also fails, falls back to `CGEvent.post` (moves visible cursor – logged as warning).
3. Every fallback is logged in JSON output:
   - `"fallback":"AXPress"` – used Accessibility API
   - `"fallback":"CGEvent"` – used global event (visible cursor movement)

The orchestrator should prefer `AXPress` over `CGEvent` when possible.
