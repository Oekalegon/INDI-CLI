import Foundation

enum Key: Sendable {
    case char(Character)
    case enter
    case backspace
    case delete
    case tab
    case up
    case down
    case left
    case right
    case home
    case end
    case ctrlC
    case ctrlD
}

/// Reads raw stdin bytes on a dedicated OS thread (blocking `read()` calls can't happen inside a
/// Swift Task without pinning a cooperative-pool thread) and decodes them into `Key` values,
/// including the handful of multi-byte ANSI escape sequences terminals send for arrow/home/end/
/// delete keys.
/// `@unchecked Sendable`: `readLoop` only reads the immutable `terminal` and writes to the
/// continuation captured by value; `continuation` itself is set once before the reader thread
/// starts and never mutated afterward.
final class KeyReader: @unchecked Sendable {
    private let terminal: RawTerminal
    private var continuation: AsyncStream<Key>.Continuation?

    init(terminal: RawTerminal) {
        self.terminal = terminal
    }

    func stream() -> AsyncStream<Key> {
        AsyncStream { continuation in
            self.continuation = continuation
            let thread = Thread { [weak self] in
                self?.readLoop(continuation: continuation)
            }
            thread.start()
        }
    }

    private func readLoop(continuation: AsyncStream<Key>.Continuation) {
        while let byte = terminal.readByte() {
            switch byte {
            case 3:
                continuation.yield(.ctrlC)
            case 4:
                continuation.yield(.ctrlD)
            case 9:
                continuation.yield(.tab)
            case 13, 10:
                continuation.yield(.enter)
            case 127, 8:
                continuation.yield(.backspace)
            case 27:
                guard let key = readEscapeSequence() else { continue }
                continuation.yield(key)
            default:
                continuation.yield(.char(Character(Unicode.Scalar(byte))))
            }
        }
        continuation.finish()
    }

    /// Decodes an ANSI escape sequence already consumed up to (and including) the initial `ESC`
    /// byte. Only handles the small subset interactive mode actually needs.
    private func readEscapeSequence() -> Key? {
        guard let second = terminal.readByte() else { return nil }
        guard second == UInt8(ascii: "[") else { return nil }
        guard let third = terminal.readByte() else { return nil }
        switch third {
        case UInt8(ascii: "A"): return .up
        case UInt8(ascii: "B"): return .down
        case UInt8(ascii: "C"): return .right
        case UInt8(ascii: "D"): return .left
        case UInt8(ascii: "H"): return .home
        case UInt8(ascii: "F"): return .end
        case UInt8(ascii: "3"):
            _ = terminal.readByte() // trailing '~'
            return .delete
        case UInt8(ascii: "1"):
            _ = terminal.readByte() // trailing '~'
            return .home
        case UInt8(ascii: "4"):
            _ = terminal.readByte() // trailing '~'
            return .end
        default:
            return nil
        }
    }
}
