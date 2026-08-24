import Foundation

/// Where a command's output goes — plain `print` to stdout in plain-CLI mode, or appended to the
/// interactive session's scrollback pane when running inside `indi-cli interactive`.
///
/// Every subcommand writes through this instead of calling `print` directly, so the exact same
/// command implementation works unmodified in both modes.
protocol OutputSink: Sendable {
    func write(_ line: String)
}

struct StdoutSink: OutputSink {
    func write(_ line: String) {
        print(line)
    }
}

/// The active sink for the current process — `main` sets this to `StdoutSink()` for plain
/// invocations and to the interactive session's pane sink for `interactive`.
final class Console: @unchecked Sendable {
    static let shared = Console()

    private let lock = NSLock()
    private var sink: OutputSink = StdoutSink()

    func use(_ sink: OutputSink) {
        lock.lock()
        defer { lock.unlock() }
        self.sink = sink
    }

    func print(_ line: String) {
        lock.lock()
        let sink = self.sink
        lock.unlock()
        sink.write(line)
    }
}
