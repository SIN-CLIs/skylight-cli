import Foundation

// MARK: - Entry Point

let argv = CommandLine.arguments

guard argv.count >= 2 else {
    Output.usage()
    exit(2)
}

let command = argv[1]
let rest = Array(argv.dropFirst(2))

do {
    switch command {
    case "screenshot":
        try CLI.screenshot(rest)
    case "click":
        try CLI.click(rest)
    case "wait-for-selector":
        try CLI.waitForSelector(rest)
    case "get-window-state":
        try CLI.getWindowState(rest)
    case "list-elements":
        try CLI.listElements(rest)
    case "version", "--version", "-v":
        Output.json(["version": SKYLIGHT_VERSION])
    case "help", "--help", "-h":
        Output.usage()
    default:
        Output.error("unknown_command", message: "Unknown command: \(command)")
        exit(2)
    }
} catch let error as CLIError {
    Output.error(error.code, message: error.message)
    exit(error.exitCode)
} catch {
    Output.error("internal_error", message: String(describing: error))
    exit(1)
}
