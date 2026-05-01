import Foundation
let args = CommandLine.arguments
guard args.count >= 2 else { print("Usage: skylight-cli <command> [options]"); exit(1) }
let command = args[1]; let rest = Array(args.dropFirst(2))
do {
switch command {
case "screenshot": try CLI.screenshot(rest)
case "click": try CLI.click(rest)
case "hold": try CLI.hold(rest)
case "type": try CLI.type(rest)
case "scroll": try Scroll.run(args: rest)
case "drag": try Drag.run(args: rest)
case "hover": try Hover.run(args: rest)
case "double-click": try DoubleClick.run(args: rest)
case "wait-for-selector": try CLI.waitForSelector(rest)
case "get-window-state": try CLI.getWindowState(rest)
case "list-elements": try CLI.listElements(rest)
default: print("{\"status\":\"error\",\"message\":\"Unknown command: \(command)\"}"); exit(1)
}
} catch let e as CLIError {
    Output.error(e.code, message: e.message)
    exit(Int32(e.exitCode))
} catch {
    Output.error("internal", message: error.localizedDescription)
    exit(1)
}