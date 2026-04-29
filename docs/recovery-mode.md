# Recovery Mode — When You Are Stuck

> **TL;DR:** If you are looping, retrying, or about to "creatively rewrite" something — STOP. Read the symptom that matches your situation below and follow the steps in order. Do not skip steps. Do not rewrite working code to "simplify."

---

## How To Use This File

1. Find the symptom that matches what you see.
2. Run the diagnostic commands in order.
3. Apply the fix. Do not improvise.
4. If no symptom matches, go to "Catch-All: Last Resort" at the bottom.
5. After recovery, append a note to this file under "Postmortems" so the next agent benefits.

---

## Symptom: `swift build` fails with "no such module"

**Diagnostic:**
```bash
swift --version       # must be 5.7+
sw_vers               # macOS 12+ (ProductVersion >= 12.0)
xcode-select -p       # must point at a real Xcode or CommandLineTools
```

**Likely cause:** No Xcode toolchain installed, or pointing at a stale path.

**Fix:**
```bash
# If CommandLineTools missing:
xcode-select --install

# If Xcode is installed but toolchain mismatch:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Do NOT:** Add `import Foundation` shims, downgrade Swift, or rewrite to plain C. The module system is fine; your environment is broken.

---

## Symptom: `swift build` fails with "use of unresolved identifier 'AXUIElement…'"

**Diagnostic:** Confirm `Sources/skylight/AXElementFinder.swift` has `import ApplicationServices` at top.

**Fix:** Add the import. Do NOT add a `linkerSettings` or `cSettings` flag — `ApplicationServices` is part of the macOS SDK and Swift finds it via the standard system search paths.

---

## Symptom: Binary builds, but `get-window-state --pid X` returns `status: error, code: window_not_found`

**Diagnostic 1 — Is the PID right?**
```bash
ps -p $PID -o command=
# Should print the app's command line. If empty: bad PID.
```

**Diagnostic 2 — Does the app actually have a layer-0 window?**
```bash
osascript -e "tell application \"System Events\" to get name of every process whose unix id is $PID"
# If empty: app is background-only.
```

**Diagnostic 3 — Window too small?** Edit `WindowCapture.swift` and temporarily lower `minSize` from `200` to `50` to debug. Revert before commit.

**Most common fix:** The app has not finished launching. Add a 500ms sleep in the orchestrator after `playstealth-cli launch`, or use `wait-for-selector --role AXWindow --timeout 10`.

**Do NOT:** Disable the layer-0 filter. You will start matching tooltips, autofill popups, and `Window Server` shadow windows, and your clicks will land in random places.

---

## Symptom: Click "succeeds" (exit 0, `status:ok`) but the target app does not react

**This is the #1 most common bug. Read this whole section.**

**Diagnostic 1 — Did the primer fire?**
```bash
.build/release/skylight click --pid $PID --element-index 0 | jq '.primer'
# Should be: true
# If false, you passed --no-primer or dry-run.
```

**Diagnostic 2 — Was SkyLight loaded?** Re-add a temporary stderr print in `SkyLightClicker.swift` after `dlopen`:
```swift
FileHandle.standardError.write("[skylight] handle=\(String(describing: handle))\n".data(using: .utf8)!)
```
Rebuild, run. If `handle` is nil → SkyLight could not load. Fixes:
- macOS version too new (Apple removed the framework path). Check `/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight` exists.
- SIP relevant to your environment? Unlikely on user systems, but possible on hardened enterprise Macs.

**Diagnostic 3 — `used_fallback: true` in JSON?** Then the global `CGEvent.post` ran. The visible cursor moved. The click went to whatever was under the cursor, which may not have been your target window. **This is expected behavior when SkyLight is unavailable; the orchestrator must handle it.**

**Diagnostic 4 — Coordinate offset on Retina?** Capture a SoM screenshot, manually verify badge `0` is on top of the actual element. If badges are shifted by a factor of 2 → you're hitting the **DPI bug** (logical-vs-physical points). Fix: in `SoMOverlay.swift`, divide element frames by `NSScreen.main!.backingScaleFactor`. This is a known unfixed risk; see `docs/handoff.md` Risk #4.

**Diagnostic 5 — Chromium user-activation gate?** If the target is `<input type=file>`, autoplay video, fullscreen request, or anything gated: even with primer, Chromium may still reject. Workaround: use keyboard-driven interaction via `playstealth-cli` for those specific elements.

**Do NOT:** Add a sleep loop and "click again 5 times." That is brain logic and belongs in the orchestrator. Also, multi-clicking can trigger anti-bot detection in surveys.

---

## Symptom: SoM badges land in the wrong places

**Diagnostic:**
```bash
# Save raw + som side by side
.build/release/skylight screenshot --pid $PID --mode raw --out /tmp/raw.png
.build/release/skylight screenshot --pid $PID --mode som --out /tmp/som.png
open /tmp/raw.png /tmp/som.png
```

**Cause A — DPI mismatch (Retina):** badges shifted by factor 2 → see Symptom "Click does nothing" Diagnostic 4.

**Cause B — Window scrolled / virtualized list:** AX tree returns elements that aren't currently visible (e.g., react-window). Filter applied in `AXElementFinder.swift` (`frame ⊆ window`) should catch this — verify by dumping `list-elements` and inspecting frames.

**Cause C — Iframe / plugin content:** AX tree of the host process does not include cross-origin iframe content. **This is by design and unfixable from this CLI.** Use grid mode + LLM coordinate guess as the fallback. The orchestrator should detect "low element count + visually rich screenshot" and switch to grid.

---

## Symptom: `wait-for-selector` always times out even when the element is visibly there

**Diagnostic 1 — Run `list-elements` at the same time and grep for the role/label:**
```bash
.build/release/skylight list-elements --pid $PID | jq '.elements[] | select(.label | test("Continue"; "i"))'
```
If empty: the AX tree does not expose the element. Common cause: web content rendered via canvas (Flutter, Unity, Figma, Google Sheets). **Use `--mode grid` instead. wait-for-selector cannot help here.**

**Diagnostic 2 — Role mismatch:** AX roles are oddly specific. A "button" might be `AXButton`, `AXLink`, `AXCheckBox`, or `AXMenuItem`. Run without `--role` (label-only) to confirm.

**Fix:** Either drop `--role`, broaden to `--role AXButton --label "Continue"`, or switch to grid mode upstream.

---

## Symptom: Stdout is not valid JSON (orchestrator's `json.loads` fails)

**Diagnostic:**
```bash
.build/release/skylight <your command> 2>/dev/null | head -c 4096
```

**If you see plain text before/after JSON:** something printed to stdout instead of stderr. Find it:
```bash
git grep -n 'print(' Sources/   # only Output.json is allowed to print
git grep -n 'NSLog'             # NSLog goes to stderr but may end up wherever; banish it
```

**Fix:** All non-JSON diagnostic output must use `FileHandle.standardError.write(...)`. The only `print` in this codebase should be inside `Output.json` in `Utils.swift`.

**Do NOT:** "Solve" this by making the orchestrator's parser lenient. Strict JSON is the contract.

---

## Symptom: Codesign / notarization failure

**Quick local fix (development):**
```bash
codesign --force --deep --sign - .build/release/skylight
xattr -cr .build/release/skylight
```

**Production fix:**
- You need a Developer ID Application certificate.
- After build:
  ```bash
  codesign --force --options=runtime --timestamp --sign "Developer ID Application: <Your Name> (TEAMID)" .build/release/skylight
  zip skylight.zip .build/release/skylight
  xcrun notarytool submit skylight.zip --apple-id … --team-id … --password … --wait
  ```
- The binary cannot be `--deep` notarized if it loads private frameworks via dlopen — that's actually fine for notarization (vs. static linking which IS rejected).

---

## Symptom: AX permission prompt does not appear (and AX calls return errors)

**Diagnostic:**
```swift
let trusted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
```

If `trusted` is `false`, the prompt should have appeared. If it didn't:
- Parent process is already in the AX list but disabled. Toggle it off and on in `System Settings → Privacy & Security → Accessibility`.
- Parent process is `tmux`/`screen`. Add the wrapping terminal app, not the multiplexer.
- Headless run via SSH: AX permission cannot be granted to a non-GUI session. **Run from a logged-in console session.**

---

## Catch-All: Last Resort

If nothing matches:

1. **Stop. Do not rewrite.**
2. Write down the exact command you ran and the exact output to `docs/sessions/session-NN.md` under a "Stuck" heading.
3. `git diff main` — if you have uncommitted changes, stash them.
4. `git checkout main` and re-run the smoke test in `docs/handoff.md` "First Action."
5. If smoke test passes on `main` but fails on your branch: bisect your changes.
6. If smoke test ALSO fails on `main`: this is an environment issue (macOS update, permission revoked, Xcode update). Document it, hand off to the operator.

---

## Postmortems

> Append `### YYYY-MM-DD — short title` entries here when you solve a non-obvious failure. Future agents will thank you.

(empty — first session)
