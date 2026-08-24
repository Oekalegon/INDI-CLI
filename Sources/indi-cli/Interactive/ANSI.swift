import Foundation

enum ANSI {
    static let clearScreen = "\u{1B}[2J"
    static let clearLine = "\u{1B}[2K"
    static let hideCursor = "\u{1B}[?25l"
    static let showCursor = "\u{1B}[?25h"
    static let reset = "\u{1B}[0m"
    static let dim = "\u{1B}[2m"
    static let bold = "\u{1B}[1m"
    static let reverse = "\u{1B}[7m"
    static let yellow = "\u{1B}[33m"
    static let red = "\u{1B}[31m"
    static let green = "\u{1B}[32m"
    static let cyan = "\u{1B}[36m"

    static func moveTo(row: Int, column: Int) -> String {
        "\u{1B}[\(row);\(column)H"
    }
}

/// Writes raw bytes straight to stdout, bypassing Swift's line-buffered `print`, since interactive
/// mode repaints arbitrary screen regions with cursor-positioning escapes.
func rawWrite(_ string: String) {
    FileHandle.standardOutput.write(Data(string.utf8))
}
