import Foundation

/// One line in the interactive session's scrollback — either an echoed command, a command's own
/// output, or a line from the live INDI message stream.
struct BufferLine {
    enum Kind {
        case commandEcho
        case commandOutput
        case streamEvent
        case systemNotice
    }

    let kind: Kind
    let text: String
    /// The device this line pertains to, if any — used both for the `filter` command and for
    /// highlighting lines related to the most recently run command.
    let device: String?
}

/// Thread-safe scrollback buffer shared between the raw-input loop (main thread) and the
/// background tasks reading command output / the live message stream. A plain lock-protected
/// class rather than an actor: redraws need to read the buffer synchronously from the input loop
/// without an `await`, since that loop is itself driving blocking `read()` calls.
final class MessageBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [BufferLine] = []

    /// Substring filter applied to `visibleLines` — `nil` shows everything. Case-insensitive,
    /// matched against both the line's text and its device.
    var filter: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _filter
        }
        set {
            lock.lock()
            _filter = newValue
            lock.unlock()
        }
    }
    private var _filter: String?

    /// The device (if any) the most recently dispatched command targeted — lines mentioning it
    /// are drawn highlighted so a live stream of unrelated devices doesn't bury the command's own
    /// effect.
    var highlightedDevice: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _highlightedDevice
        }
        set {
            lock.lock()
            _highlightedDevice = newValue
            lock.unlock()
        }
    }
    private var _highlightedDevice: String?

    func clear() {
        lock.lock()
        lines.removeAll()
        lock.unlock()
    }

    func append(_ line: BufferLine) {
        lock.lock()
        lines.append(line)
        if lines.count > 5000 {
            lines.removeFirst(lines.count - 5000)
        }
        lock.unlock()
    }

    /// Lines matching the current filter, each paired with whether it should be drawn
    /// highlighted (matches `highlightedDevice`).
    func visibleLines() -> [(line: BufferLine, highlighted: Bool)] {
        lock.lock()
        let snapshot = lines
        let currentFilter = _filter?.lowercased()
        let highlightDevice = _highlightedDevice
        lock.unlock()

        return snapshot
            .filter { line in
                guard let currentFilter, !currentFilter.isEmpty else { return true }
                return line.text.lowercased().contains(currentFilter)
                    || (line.device?.lowercased().contains(currentFilter) ?? false)
            }
            .map { line in
                (line, highlightDevice != nil && line.device == highlightDevice)
            }
    }
}
