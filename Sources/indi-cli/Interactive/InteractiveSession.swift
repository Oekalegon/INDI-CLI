import ArgumentParser
import Foundation
import INDIMCPKit

/// An `OutputSink` that appends every line a dispatched command prints to the session's shared
/// scrollback buffer, tagged with the device the command targeted (for filtering/highlighting),
/// and triggers a repaint after each line.
private final class InteractiveOutputSink: OutputSink {
    let buffer: MessageBuffer
    let device: String?
    let onWrite: @Sendable () -> Void

    init(buffer: MessageBuffer, device: String?, onWrite: @escaping @Sendable () -> Void) {
        self.buffer = buffer
        self.device = device
        self.onWrite = onWrite
    }

    func write(_ line: String) {
        buffer.append(BufferLine(kind: .commandOutput, text: line, device: device))
        onWrite()
    }
}

/// Runs the split-pane interactive shell: a scrolling message pane (command output interleaved
/// with the live INDI message stream, filterable and highlightable) above a persistent, tab-
/// completing input line — see `InteractiveCommand`'s doc comment for the feature this
/// implements.
/// `@unchecked Sendable`: mutable state (`inputLine`, `pendingCompletions`, `client`,
/// `listenTask`) is only ever touched from the single input loop in `run()`. Background tasks
/// (the message-stream listener, a dispatched command's output sink) only call `render()`, which
/// reads `terminal`/`buffer` — both already safe for concurrent access on their own — and never
/// touches this class's other stored properties.
final class InteractiveSession: @unchecked Sendable {
    private let endpointOptions: ClientEndpointOptions
    private let terminal = RawTerminal()
    private let buffer = MessageBuffer()
    private var inputLine = InputLine()
    private var client: INDIMCPClient?
    private var listenTask: Task<Void, Never>?
    private var pendingCompletions: [String] = []

    init(endpointOptions: ClientEndpointOptions) {
        self.endpointOptions = endpointOptions
    }

    func run() async {
        terminal.enableRawMode()
        rawWrite(ANSI.hideCursor)
        defer {
            listenTask?.cancel()
            rawWrite(ANSI.showCursor)
            terminal.restore()
            print()
        }

        buffer.append(BufferLine(kind: .systemNotice, text: "Connecting to \(endpointOptions.endpoint)…", device: nil))
        render()
        do {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            self.client = client
            buffer.append(BufferLine(kind: .systemNotice, text: "Connected. Type 'help' for commands.", device: nil))
        } catch {
            buffer.append(BufferLine(kind: .systemNotice, text: "Connection failed: \(error)", device: nil))
        }
        render()

        let reader = KeyReader(terminal: terminal)
        for await key in reader.stream() {
            switch key {
            case .ctrlC, .ctrlD:
                return
            case .char(let character):
                inputLine.insert(character)
                pendingCompletions = []
            case .backspace:
                inputLine.backspace()
                pendingCompletions = []
            case .delete:
                inputLine.deleteForward()
                pendingCompletions = []
            case .left:
                inputLine.moveLeft()
            case .right:
                inputLine.moveRight()
            case .up:
                inputLine.historyPrevious()
                pendingCompletions = []
            case .down:
                inputLine.historyNext()
                pendingCompletions = []
            case .home:
                inputLine.moveToStart()
            case .end:
                inputLine.moveToEnd()
            case .tab:
                pendingCompletions = inputLine.complete()
            case .enter:
                let submitted = inputLine.submit()
                pendingCompletions = []
                if !submitted.isEmpty {
                    buffer.append(BufferLine(kind: .commandEcho, text: "> \(submitted)", device: nil))
                    render()
                    await dispatch(submitted)
                }
                if shouldQuit(submitted) { return }
            }
            render()
        }
    }

    // MARK: - Dispatch

    private func shouldQuit(_ line: String) -> Bool {
        let word = line.trimmingCharacters(in: .whitespaces).lowercased()
        return word == "quit" || word == "exit"
    }

    private func dispatch(_ line: String) async {
        let tokens = tokenize(line)
        guard let first = tokens.first else { return }

        switch first {
        case "quit", "exit":
            return
        case "help":
            printHelp()
            return
        case "clear":
            buffer.clear()
            return
        case "filter":
            let text = tokens.dropFirst().joined(separator: " ")
            if text.isEmpty || text == "clear" {
                buffer.filter = nil
                buffer.append(BufferLine(kind: .systemNotice, text: "Filter cleared.", device: nil))
            } else {
                buffer.filter = text
                buffer.append(BufferLine(kind: .systemNotice, text: "Filtering on '\(text)'.", device: nil))
            }
            return
        case "listen":
            startListening(device: tokens.count > 1 ? tokens[1] : nil)
            return
        default:
            break
        }

        guard let client else {
            buffer.append(BufferLine(kind: .systemNotice, text: "Not connected.", device: nil))
            return
        }

        let device = await resolveHighlightDevice(tokens: tokens, client: client)
        buffer.highlightedDevice = device

        let sink = InteractiveOutputSink(buffer: buffer, device: device) { [weak self] in self?.render() }
        Console.shared.use(sink)
        defer { Console.shared.use(StdoutSink()) }

        do {
            var command = try IndiCLI.parseAsRoot(tokens)
            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            let message = IndiCLI.fullMessage(for: error)
            buffer.append(BufferLine(kind: .commandOutput, text: message, device: device))
        }
    }

    /// Resolves the INDI device name a device-role subcommand's `--rig` targets, so stream lines
    /// for that device can be drawn highlighted — best-effort, `nil` if the command isn't a
    /// device command or the rig/role has no resolved device.
    private func resolveHighlightDevice(tokens: [String], client: INDIMCPClient) async -> String? {
        let roleByCommand: [String: Role] = [
            "mount": .mount, "camera": .camera, "filterwheel": .filterWheel, "focuser": .focuser,
        ]
        guard let root = tokens.first, let role = roleByCommand[root] else { return nil }
        guard let rigIndex = tokens.firstIndex(of: "--rig"), tokens.count > rigIndex + 1 else { return nil }
        let rigId = tokens[rigIndex + 1]
        guard let rig = try? await client.getRig(id: rigId) else { return nil }
        return rig.components.first(where: { $0.role == role })?.device
    }

    private func startListening(device: String?) {
        guard let client else {
            buffer.append(BufferLine(kind: .systemNotice, text: "Not connected.", device: nil))
            return
        }
        listenTask?.cancel()
        buffer.append(BufferLine(
            kind: .systemNotice,
            text: device.map { "Listening for messages on '\($0)'…" } ?? "Listening for all messages…",
            device: nil
        ))
        listenTask = Task { [weak self] in
            guard let self else { return }
            var seen = Set<IndiEvent>()
            do {
                for try await window in client.messageEvents(device: device) {
                    for event in window.reversed() where !seen.contains(event) {
                        seen.insert(event)
                        self.buffer.append(BufferLine(
                            kind: .streamEvent,
                            text: self.format(event),
                            device: event.device
                        ))
                    }
                    self.render()
                }
            } catch {
                if !Task.isCancelled {
                    self.buffer.append(BufferLine(kind: .systemNotice, text: "Message stream ended: \(error)", device: nil))
                    self.render()
                }
            }
        }
    }

    private func format(_ event: IndiEvent) -> String {
        var parts = [event.timestamp]
        if let device = event.device { parts.append(device) }
        if let name = event.name { parts.append(name) }
        if let message = event.message { parts.append(message) }
        return parts.joined(separator: " — ")
    }

    private func printHelp() {
        let lines = [
            "Commands: rig, observatory, server, messaging, mount, camera, filterwheel, focuser, script",
            "  listen [device]   start streaming INDI messages, optionally scoped to one device",
            "  filter <text>     show only lines containing <text> (device or message)",
            "  filter clear      remove the current filter",
            "  clear             clear the scrollback",
            "  quit / exit       leave interactive mode",
            "Use --help after any command (e.g. 'camera capture --help') for its full option list.",
        ]
        for line in lines {
            buffer.append(BufferLine(kind: .systemNotice, text: line, device: nil))
        }
    }

    /// Splits a line into words, honoring double-quoted segments as single words (so e.g.
    /// `script run flat --param name="M31 flats"` works).
    private func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false
        for character in line {
            if character == "\"" {
                inQuotes.toggle()
            } else if character == " " && !inQuotes {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    // MARK: - Rendering

    private func render() {
        let (columns, rows) = terminal.size
        let inputRow = rows
        let separatorRow = rows - 1
        let paneHeight = max(0, rows - 2)

        var output = ANSI.hideCursor
        output += ANSI.clearScreen
        output += ANSI.moveTo(row: 1, column: 1)

        let visible = buffer.visibleLines()
        let start = max(0, visible.count - paneHeight)
        for (offset, entry) in visible[start...].enumerated() {
            output += ANSI.moveTo(row: offset + 1, column: 1)
            output += ANSI.clearLine
            output += render(entry.line, highlighted: entry.highlighted, width: columns)
        }

        output += ANSI.moveTo(row: separatorRow, column: 1)
        output += ANSI.dim + String(repeating: "─", count: columns) + ANSI.reset

        let prompt = "indi> "
        output += ANSI.moveTo(row: inputRow, column: 1)
        output += ANSI.clearLine
        output += prompt + inputLine.text
        if !pendingCompletions.isEmpty {
            output += "  " + ANSI.dim + pendingCompletions.joined(separator: "  ") + ANSI.reset
        }
        output += ANSI.moveTo(row: inputRow, column: prompt.count + inputLine.cursor + 1)
        output += ANSI.showCursor

        rawWrite(output)
    }

    private func render(_ line: BufferLine, highlighted: Bool, width: Int) -> String {
        let color: String
        switch line.kind {
        case .commandEcho: color = ANSI.bold + ANSI.cyan
        case .commandOutput: color = ""
        case .streamEvent: color = ANSI.dim
        case .systemNotice: color = ANSI.yellow
        }
        var text = line.text
        if text.count > width {
            text = String(text.prefix(width))
        }
        let prefix = highlighted ? ANSI.reverse : color
        let suffix = (highlighted || !color.isEmpty) ? ANSI.reset : ""
        return prefix + text + suffix
    }
}
