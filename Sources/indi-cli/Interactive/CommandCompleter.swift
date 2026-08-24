/// Static mirror of the plain-CLI's subcommand tree, used only for interactive-mode tab
/// completion — not the source of truth for parsing (each command's own `AsyncParsableCommand`
/// is), just enough structure to complete a partially-typed command word.
enum CommandCompleter {
    static let tree: [String: [String]] = [
        "rig": ["list", "show"],
        "observatory": ["list", "show"],
        "server": ["status", "start", "stop", "restart"],
        "messaging": ["status", "start", "stop"],
        "mount": ["connect", "disconnect", "park", "unpark", "slew", "track-off", "track-mode"],
        "camera": [
            "connect", "disconnect", "cooler-on", "cooler-off", "cool",
            "capture", "capture-darks", "capture-bias", "capture-flats", "capture-lights",
        ],
        "filterwheel": ["connect", "disconnect", "select"],
        "focuser": ["connect", "disconnect", "set-position"],
        "script": ["list", "run", "status", "cancel", "pause", "resume"],
        "listen": [],
        "filter": [],
        "clear": [],
        "help": [],
        "quit": [],
        "exit": [],
    ]

    /// Completions for the word at `wordIndex` in `words` (the input line split on whitespace),
    /// given `prefix` typed so far for that word.
    static func completions(words: [String], wordIndex: Int, prefix: String) -> [String] {
        if wordIndex == 0 {
            return tree.keys.filter { $0.hasPrefix(prefix) }.sorted()
        }
        guard let root = words.first, let subcommands = tree[root] else { return [] }
        return subcommands.filter { $0.hasPrefix(prefix) }.sorted()
    }
}
