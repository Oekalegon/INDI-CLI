import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

/// Puts stdin into raw mode (no line buffering, no local echo) for the duration of interactive
/// mode, restoring the original settings on `restore()`/`deinit`. Also reads the terminal's
/// current size via `TIOCGWINSZ`.
final class RawTerminal {
    private var originalTermios = termios()
    private(set) var isRaw = false

    /// Current terminal size in character cells.
    var size: (columns: Int, rows: Int) {
        var winSize = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &winSize) == 0, winSize.ws_col > 0, winSize.ws_row > 0 {
            return (Int(winSize.ws_col), Int(winSize.ws_row))
        }
        return (80, 24)
    }

    func enableRawMode() {
        guard !isRaw else { return }
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        raw.c_lflag &= ~UInt(ECHO | ICANON | ISIG | IEXTEN)
        raw.c_iflag &= ~UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        raw.c_oflag &= ~UInt(OPOST)
        let ccSize = MemoryLayout.size(ofValue: raw.c_cc)
        withUnsafeMutablePointer(to: &raw.c_cc) { pointer in
            pointer.withMemoryRebound(to: UInt8.self, capacity: ccSize) { cc in
                cc[Int(VMIN)] = 1 // return as soon as 1 byte is available
                cc[Int(VTIME)] = 0 // no timeout
            }
        }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRaw = true
    }

    func restore() {
        guard isRaw else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        isRaw = false
    }

    /// Reads one raw byte from stdin, blocking until available.
    func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let count = read(STDIN_FILENO, &byte, 1)
        return count == 1 ? byte : nil
    }

    deinit {
        restore()
    }
}
