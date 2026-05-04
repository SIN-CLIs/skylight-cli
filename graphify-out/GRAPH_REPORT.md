# Graph Report - skylight-cli  (2026-05-04)

## Corpus Check
- 20 files · ~21,120 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 121 nodes · 167 edges · 17 communities detected
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 29 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]

## God Nodes (most connected - your core abstractions)
1. `ArgParser` - 20 edges
2. `CLIError` - 18 edges
3. `AXElementFinder` - 9 edges
4. `AXElementFinderTests` - 8 edges
5. `UtilsTests` - 8 edges
6. `CLI` - 8 edges
7. `Output` - 7 edges
8. `JSONContractTests` - 6 edges
9. `OutputTests` - 5 edges
10. `UtilsTests` - 4 edges

## Surprising Connections (you probably didn't know these)
- `AXElementFinderTests` --inherits--> `XCTestCase`  [EXTRACTED]
  Tests/SkylightCliTests/AXElementFinderTests.swift →   _Bridges community 4 → community 2_
- `UtilsTests` --inherits--> `XCTestCase`  [EXTRACTED]
  Tests/SkylightCliTests/UtilsTests.swift →   _Bridges community 2 → community 5_
- `JSONContractTests` --inherits--> `XCTestCase`  [EXTRACTED]
  Tests/SkylightCliTests/JSONContractTests.swift →   _Bridges community 2 → community 6_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.2
Nodes (4): Error, CLI, ArgParser, CLIError

### Community 1 - "Community 1"
Cohesion: 0.2
Nodes (3): Output, PNGWriter, SKLEnvironment

### Community 2 - "Community 2"
Cohesion: 0.16
Nodes (5): OutputTests, UtilsTests, VersionTests, SmokeTests, XCTestCase

### Community 3 - "Community 3"
Cohesion: 0.35
Nodes (2): AXElement, AXElementFinder

### Community 4 - "Community 4"
Cohesion: 0.25
Nodes (1): AXElementFinderTests

### Community 5 - "Community 5"
Cohesion: 0.25
Nodes (1): UtilsTests

### Community 6 - "Community 6"
Cohesion: 0.33
Nodes (1): JSONContractTests

### Community 7 - "Community 7"
Cohesion: 0.53
Nodes (3): WindowCapture, WindowCaptureResult, WindowInfo

### Community 8 - "Community 8"
Cohesion: 0.4
Nodes (2): ClickResult, SkyLightClicker

### Community 9 - "Community 9"
Cohesion: 0.6
Nodes (2): OCRGrounding, OCRRegion

### Community 10 - "Community 10"
Cohesion: 0.5
Nodes (1): SoMOverlay

### Community 11 - "Community 11"
Cohesion: 0.67
Nodes (1): SkylightCli

### Community 12 - "Community 12"
Cohesion: 0.67
Nodes (1): Scroll

### Community 13 - "Community 13"
Cohesion: 0.67
Nodes (1): Drag

### Community 14 - "Community 14"
Cohesion: 0.67
Nodes (1): Hover

### Community 15 - "Community 15"
Cohesion: 0.67
Nodes (1): DoubleClick

### Community 16 - "Community 16"
Cohesion: 0.67
Nodes (1): Hold

## Knowledge Gaps
- **Thin community `Community 3`** (11 nodes): `AXElement`, `AXElementFinder`, `.bestLabel()`, `.collect()`, `.enrollAXTreeWakeup()`, `.frame()`, `.interactiveElements()`, `.isAXTrusted()`, `.stringArrayAttr()`, `.stringAttr()`, `AXElementFinder.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 4`** (8 nodes): `AXElementFinderTests`, `.test_interacting_roles_contains_button()`, `.test_interacting_roles_contains_checkbox()`, `.test_interacting_roles_contains_link()`, `.test_interacting_roles_contains_textfield()`, `.test_interacting_roles_count_minimum()`, `.test_webarea_in_roles()`, `AXElementFinderTests.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 5`** (8 nodes): `UtilsTests`, `.test_element_not_found_error()`, `.test_environment_debug_default_off()`, `.test_json_error_output()`, `.test_missing_pid_error()`, `.test_skylight_version_defined()`, `.test_version_matches_semver()`, `UtilsTests.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 6`** (6 nodes): `JSONContractTests`, `.test_exit_code_1_generic()`, `.test_exit_code_2_missing_pid()`, `.test_exit_code_3_not_found()`, `.test_exit_code_5_timeout()`, `JSONContractTests.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 8`** (6 nodes): `ClickResult`, `SkyLightClicker`, `.axPress()`, `.click()`, `.typeText()`, `SkyLightClicker.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 9`** (5 nodes): `OCRGrounding`, `.applyOCR()`, `.detectTextRegions()`, `OCRRegion`, `OCRGrounding.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 10`** (4 nodes): `SoMOverlay`, `.applyGrid()`, `.applySoM()`, `SoMOverlay.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 11`** (3 nodes): `skylight-cli.rb`, `SkylightCli`, `.install()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (3 nodes): `Scroll`, `.run()`, `Scroll.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 13`** (3 nodes): `Drag`, `.run()`, `Drag.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (3 nodes): `Hover`, `.run()`, `Hover.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (3 nodes): `DoubleClick`, `.run()`, `DoubleClick.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 16`** (3 nodes): `Hold`, `.run()`, `Hold.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ArgParser` connect `Community 0` to `Community 1`, `Community 12`, `Community 13`, `Community 14`, `Community 15`?**
  _High betweenness centrality (0.345) - this node is a cross-community bridge._
- **Why does `CLIError` connect `Community 0` to `Community 1`, `Community 2`, `Community 5`, `Community 6`, `Community 7`, `Community 16`?**
  _High betweenness centrality (0.343) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `ArgParser` (e.g. with `.run()` and `.run()`) actually correct?**
  _`ArgParser` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 14 inferred relationships involving `CLIError` (e.g. with `.test_element_not_found_error()` and `.test_json_error_output()`) actually correct?**
  _`CLIError` has 14 INFERRED edges - model-reasoned connections that need verification._