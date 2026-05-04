import Foundation
#if canImport(AppKit)
import AppKit
#endif

let SKYLIGHT_VERSION = "0.2.0"

enum CLI {

    // MARK: screenshot

    static func screenshot(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        let mode = opts.string("--mode") ?? "raw"        // raw | som | grid
        let output = opts.string("--out") ?? "skylight_screenshot.png"
        let gridStep = opts.int("--grid-step") ?? 50
        let dryRun = opts.flag("--dry-run")
        let includeTree = opts.flag("--include-tree")

        let capture = try WindowCapture.capture(pid: pid)

        var elements: [AXElement] = []
        var rendered = capture.image

        switch mode {
        case "raw":
            break
        case "som":
            elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
            rendered = SoMOverlay.applySoM(to: capture.image, elements: elements, windowOrigin: capture.frame.origin)
        case "grid":
            rendered = SoMOverlay.applyGrid(to: capture.image, step: CGFloat(gridStep))
        case "ocr":
            rendered = OCRGrounding.applyOCR(to: capture.image)
        default:
            throw CLIError(code: "bad_mode", message: "Unknown mode: \(mode). Use raw|som|grid|ocr", exitCode: 2)
        }

        if !dryRun {
            try PNGWriter.write(rendered, to: URL(fileURLWithPath: output))
        }

        let fileValue: Any = dryRun ? NSNull() : output
        var payload: [String: Any] = [
            "status": "ok",
            "command": "screenshot",
            "pid": pid,
            "mode": mode,
            "file": fileValue,
            "dry_run": dryRun,
            "window": [
                "x": capture.frame.origin.x,
                "y": capture.frame.origin.y,
                "width": capture.frame.size.width,
                "height": capture.frame.size.height,
                "id": capture.windowID
            ] as [String: Any]
        ]
        if includeTree || mode == "som" {
            payload["elements"] = elements.enumerated().map { (idx, el) in
                [
                    "index": idx,
                    "role": el.role,
                    "label": el.label,
                    "path": el.path,
                    "frame": [
                        "x": el.frame.origin.x,
                        "y": el.frame.origin.y,
                        "width": el.frame.size.width,
                        "height": el.frame.size.height
                    ]
                ] as [String: Any]
            }
        }
        Output.json(payload)
    }

    // MARK: click

    static func click(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        let dryRun = opts.flag("--dry-run")
        let usePrimer = !opts.flag("--no-primer")
        let button = opts.string("--button") ?? "left"

        // Drei Wege ein Ziel zu wählen: index | x,y | role+label
        var target: CGPoint?
        var resolvedIndex: Int?
        var resolvedElement: AXElement?

        if let idx = opts.int("--element-index") {
            let capture = try WindowCapture.capture(pid: pid)
            let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
            guard idx >= 0 && idx < elements.count else {
                throw CLIError(code: "element_not_found",
                               message: "Element index \(idx) out of range (have \(elements.count))",
                               exitCode: 3)
            }
            let el = elements[idx]
            target = CGPoint(x: el.frame.midX, y: el.frame.midY)
            resolvedIndex = idx
            resolvedElement = el
        } else if let x = opts.double("--x"), let y = opts.double("--y") {
            target = CGPoint(x: x, y: y)
        } else if let label = opts.string("--label") {
            let capture = try WindowCapture.capture(pid: pid)
            let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
            guard let match = elements.enumerated().first(where: { $0.element.label.localizedCaseInsensitiveContains(label) }) else {
                throw CLIError(code: "element_not_found",
                               message: "No element with label containing: \(label)",
                               exitCode: 3)
            }
            target = CGPoint(x: match.element.frame.midX, y: match.element.frame.midY)
            resolvedIndex = match.offset
            resolvedElement = match.element
        } else {
            throw CLIError(code: "bad_args",
                           message: "Provide --element-index N | --x X --y Y | --label TEXT",
                           exitCode: 2)
        }

        guard let point = target else {
            throw CLIError(code: "internal_error", message: "no_target_resolved", exitCode: 1)
        }

        if !dryRun {
            if usePrimer {
                let capture = try? WindowCapture.capture(pid: pid)
                let primer = capture.map { CGPoint(x: $0.frame.origin.x - 1, y: $0.frame.origin.y - 1) }
                            ?? CGPoint(x: 0, y: 0)
                _ = SkyLightClicker.click(at: primer, targetPID: pid, button: button)
            }

            let usedAXPress: Bool
            if let el = resolvedElement {
                usedAXPress = SkyLightClicker.axPress(element: el.axElement)
            } else {
                usedAXPress = false
            }

            if !usedAXPress {
                let result = SkyLightClicker.click(at: point, targetPID: pid, button: button)
                if !result.posted {
                    throw CLIError(code: "click_failed",
                                   message: "CGEvent.post failed",
                                   exitCode: 4)
                }
            }
        }

        var payload: [String: Any] = [
            "status": "ok",
            "command": "click",
            "pid": pid,
            "dry_run": dryRun,
            "primer": usePrimer && !dryRun,
            "button": button,
            "point": ["x": point.x, "y": point.y]
        ]
        if let idx = resolvedIndex { payload["element_index"] = idx }
        if let el = resolvedElement {
            payload["element"] = [
                "role": el.role,
                "label": el.label,
                "path": el.path
            ]
        }
        Output.json(payload)
    }

    // MARK: wait-for-selector

    static func waitForSelector(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        let role = opts.string("--role")
        let label = opts.string("--label")
        let timeout = opts.double("--timeout") ?? 15.0
        let pollMs = opts.int("--poll-ms") ?? 250

        if role == nil && label == nil {
            throw CLIError(code: "bad_args", message: "Provide --role and/or --label", exitCode: 2)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let capture = try? WindowCapture.capture(pid: pid) {
                let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
                if let (idx, el) = elements.enumerated().first(where: { (_, e) in
                    let roleMatch = role.map { e.role == $0 || e.role.contains($0) } ?? true
                    let labelMatch = label.map { e.label.localizedCaseInsensitiveContains($0) } ?? true
                    return roleMatch && labelMatch
                }) {
                    Output.json([
                        "status": "ok",
                        "command": "wait-for-selector",
                        "found": true,
                        "element_index": idx,
                        "role": el.role,
                        "label": el.label,
                        "frame": [
                            "x": el.frame.origin.x,
                            "y": el.frame.origin.y,
                            "width": el.frame.size.width,
                            "height": el.frame.size.height
                        ]
                    ])
                    return
                }
            }
            Thread.sleep(forTimeInterval: Double(pollMs) / 1000.0)
        }
        throw CLIError(code: "timeout",
                       message: "Selector not found within \(timeout)s",
                       exitCode: 5)
    }

    // MARK: get-window-state

    static func getWindowState(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        let capture = try WindowCapture.capture(pid: pid)
        Output.json([
            "status": "ok",
            "command": "get-window-state",
            "pid": pid,
            "window_id": capture.windowID,
            "title": capture.title,
            "frame": [
                "x": capture.frame.origin.x,
                "y": capture.frame.origin.y,
                "width": capture.frame.size.width,
                "height": capture.frame.size.height
            ],
            "on_screen": capture.onScreen
        ])
    }

    // MARK: list-elements

    static func listElements(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        let capture = try WindowCapture.capture(pid: pid)
        let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
        Output.json([
            "status": "ok",
            "command": "list-elements",
            "pid": pid,
            "count": elements.count,
            "elements": elements.enumerated().map { (idx, el) in
                {
                    var dict: [String: Any] = [
                        "index": idx,
                        "role": el.role,
                        "label": el.label,
                        "path": el.path,
                        "frame": [
                            "x": el.frame.origin.x,
                            "y": el.frame.origin.y,
                            "width": el.frame.size.width,
                            "height": el.frame.size.height
                        ]
                    ]
                    if let domId = el.domId { dict["dom_id"] = domId }
                    if let domClasses = el.domClasses { dict["dom_classes"] = domClasses }
                    return dict
                }()
            }
        ])
    }
    static func hold(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        guard let idx = opts.int("--element-index") else {
            throw CLIError(code: "bad_args", message: "--element-index required", exitCode: 2)
        }
        let duration = opts.int("--duration") ?? 3000
        try Hold.run(pid: pid, elementIndex: idx, durationMs: duration)
    }

    static func type(_ args: [String]) throws {
        let opts = ArgParser(args)
        guard let pid = opts.pid("--pid") else { throw CLIError.missingPID }
        guard let idx = opts.int("--element-index") else {
            throw CLIError(code: "bad_args", message: "--element-index required", exitCode: 2)
        }
        guard let text = opts.string("--text") ?? opts.string("--value") else {
            throw CLIError(code: "bad_args", message: "--text required", exitCode: 2)
        }
        let capture = try WindowCapture.capture(pid: pid)
        let elements = AXElementFinder.interactiveElements(pid: pid, windowFrame: capture.frame)
        guard idx >= 0 && idx < elements.count else {
            throw CLIError(code: "element_not_found",
                           message: "Element index \(idx) out of range (have \(elements.count))",
                           exitCode: 3)
        }
        let el = elements[idx]
        let typed = SkyLightClicker.typeText(element: el.axElement, text: text)
        Output.json([
            "status": typed ? "ok" : "error",
            "command": "type",
            "pid": pid,
            "element_index": idx,
            "element": ["role": el.role, "label": el.label, "path": el.path],
            "text": text,
            "typed": typed
        ])
    }
}
