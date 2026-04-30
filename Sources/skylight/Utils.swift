import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#endif

// MARK: - Environment

enum SKLEnvironment {
    static let isDebug = ProcessInfo.processInfo.environment["SKL_DEBUG"] == "1"
    
    static func logDebug(_ message: String) {
        guard isDebug else { return }
        FileHandle.standardError.write(Data(("[DEBUG] \(message)\n").utf8))
    }
}

// MARK: - Errors

struct CLIError: Error {
    let code: String
    let message: String
    let exitCode: Int32
    let context: [String: String]?

    init(code: String, message: String, exitCode: Int32 = 1, context: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.exitCode = exitCode
        self.context = context
    }

    static let missingPID = CLIError(code: "missing_pid", message: "--pid is required", exitCode: 2)
}

// MARK: - JSON Output

enum Output {
    static func json(_ payload: [String: Any]) {
        let safe = sanitize(payload)
        if let data = try? JSONSerialization.data(withJSONObject: safe, options: [.prettyPrinted, .sortedKeys]),
           let s = String(data: data, encoding: .utf8) {
            print(s)
        } else {
            print("{\"status\":\"ok\"}")
        }
    }

    static func error(_ code: String, message: String) {
        let payload: [String: Any] = [
            "status": "error",
            "error": code,
            "message": message,
            "version": SKYLIGHT_VERSION
        ]
        FileHandle.standardError.write(Data((toJSON(payload) + "\n").utf8))
    }
    
    static func errorWithContext(_ error: CLIError) {
        var payload: [String: Any] = [
            "status": "error",
            "error": error.code,
            "message": error.message,
            "version": SKYLIGHT_VERSION
        ]
        if let ctx = error.context {
            payload["context"] = ctx
        }
        FileHandle.standardError.write(Data((toJSON(payload) + "\n").utf8))
    }

    static func usage() {
        let text = """
        skylight-cli \(SKYLIGHT_VERSION)

        USAGE
          skylight <command> [options]

        COMMANDS
          screenshot         Capture window of a process
            --pid INT             (required) Target process ID
            --mode raw|som|grid   Default: raw
            --out PATH            Default: skylight_screenshot.png
            --grid-step INT       Default: 50 (pixels, only for grid mode)
            --include-tree        Include AX element tree in JSON
            --dry-run             Do everything except write the file

          click              Click into a window without stealing the system cursor
            --pid INT             (required)
            --element-index INT   Click element by index (from list-elements / som)
            --x FLOAT --y FLOAT   Or click at absolute screen coordinate
            --label TEXT          Or click first element matching this label
            --button left|right   Default: left
            --no-primer           Skip the priming click (Chromium activation)
            --dry-run             Resolve target but do not post events

          wait-for-selector  Wait until element appears
            --pid INT             (required)
            --role STRING         AX role (e.g. AXButton, AXLink)
            --label STRING        Substring match on label
            --timeout FLOAT       Seconds, default 15
            --poll-ms INT         Default 250

          get-window-state   Window geometry + title for a PID
            --pid INT             (required)

          list-elements      Dump interactive AX tree as JSON
            --pid INT             (required)

          version | help

        OUTPUT
          All commands print a single JSON object on stdout. Errors go to stderr.

        STEALTH NOTES
          - Posts events via private CGEventPostToPid (loaded from SkyLight.framework
            at runtime). If unavailable, falls back to global CGEvent.post which
            steals the system cursor. The JSON response includes used_fallback so
            the orchestrator can decide whether to abort.
          - Requires Accessibility permission (System Settings > Privacy & Security
            > Accessibility) for the calling terminal binary.
        """
        print(text)
    }

    private static func toJSON(_ obj: [String: Any]) -> String {
        let safe = sanitize(obj)
        if let data = try? JSONSerialization.data(withJSONObject: safe),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "{}"
    }

    /// JSONSerialization akzeptiert keine NSNull-freien Custom-Typen oder CGFloat.
    /// Wir konvertieren rekursiv in JSON-sichere Typen.
    private static func sanitize(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (k, v) in dict {
                out[k] = sanitize(v)
            }
            return out
        }
        if let arr = value as? [Any] {
            return arr.map { sanitize($0) }
        }
        if let f = value as? CGFloat {
            return Double(f)
        }
        if let pid = value as? pid_t {
            return Int(pid)
        }
        if let wid = value as? UInt32 {
            return Int(wid)
        }
        if value is NSNull { return NSNull() }
        return value
    }
}

// MARK: - Argument Parser

struct ArgParser {
    private let args: [String]
    private let flags: Set<String>

    init(_ args: [String]) {
        self.args = args
        var fl = Set<String>()
        for a in args where a.hasPrefix("--") {
            fl.insert(a)
        }
        self.flags = fl
    }

    func string(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        let next = args[i + 1]
        if next.hasPrefix("--") { return nil }
        return next
    }

    func int(_ key: String) -> Int? {
        string(key).flatMap { Int($0) }
    }

    func double(_ key: String) -> Double? {
        string(key).flatMap { Double($0) }
    }

    func pid(_ key: String) -> pid_t? {
        string(key).flatMap { Int32($0) }
    }

    func flag(_ key: String) -> Bool {
        flags.contains(key)
    }
    
    func hasFlag(_ key: String) -> Bool {
        flags.contains(key)
    }
    
    /// Validates that at least one of the provided keys is present
    func requireOneOf(_ keys: [String]) -> String? {
        for key in keys {
            if string(key) != nil { return key }
        }
        return nil
    }
}

// MARK: - PNG Writer

#if canImport(AppKit)
enum PNGWriter {
    static func write(_ image: CGImage, to url: URL) throws {
        let type = "public.png" as CFString
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
            throw CLIError(code: "io_error", message: "Cannot create PNG destination at \(url.path)", exitCode: 4)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw CLIError(code: "io_error", message: "Cannot finalize PNG at \(url.path)", exitCode: 4)
        }
    }
}
#endif
