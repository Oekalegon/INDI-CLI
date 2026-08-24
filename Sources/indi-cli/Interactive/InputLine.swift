/// Editable single-line input buffer with cursor position, command history, and tab completion —
/// the interactive prompt's model, redrawn by `InteractiveSession` on every change.
struct InputLine {
    private(set) var text = ""
    private(set) var cursor = 0
    private var history: [String] = []
    private var historyIndex: Int?
    /// The text being edited before history navigation started, restored if the user arrows back
    /// past the most recent history entry.
    private var draftBeforeHistory: String?

    mutating func insert(_ character: Character) {
        text.insert(character, at: text.index(text.startIndex, offsetBy: cursor))
        cursor += 1
    }

    mutating func backspace() {
        guard cursor > 0 else { return }
        text.remove(at: text.index(text.startIndex, offsetBy: cursor - 1))
        cursor -= 1
    }

    mutating func deleteForward() {
        guard cursor < text.count else { return }
        text.remove(at: text.index(text.startIndex, offsetBy: cursor))
    }

    mutating func moveLeft() {
        if cursor > 0 { cursor -= 1 }
    }

    mutating func moveRight() {
        if cursor < text.count { cursor += 1 }
    }

    mutating func moveToStart() {
        cursor = 0
    }

    mutating func moveToEnd() {
        cursor = text.count
    }

    mutating func clear() {
        text = ""
        cursor = 0
        historyIndex = nil
        draftBeforeHistory = nil
    }

    /// Commits the current text to history and clears the line, returning the submitted text.
    mutating func submit() -> String {
        let submitted = text
        if !submitted.isEmpty {
            history.append(submitted)
        }
        clear()
        return submitted
    }

    mutating func historyPrevious() {
        guard !history.isEmpty else { return }
        if historyIndex == nil {
            draftBeforeHistory = text
            historyIndex = history.count - 1
        } else if let index = historyIndex, index > 0 {
            historyIndex = index - 1
        }
        if let index = historyIndex {
            text = history[index]
            cursor = text.count
        }
    }

    mutating func historyNext() {
        guard let index = historyIndex else { return }
        if index + 1 < history.count {
            historyIndex = index + 1
            text = history[index + 1]
        } else {
            historyIndex = nil
            text = draftBeforeHistory ?? ""
        }
        cursor = text.count
    }

    /// Applies tab completion in place, replacing the word under the cursor with its unique
    /// completion, or with the longest common prefix of multiple matches. Returns the full match
    /// list, so the caller can display it when it's ambiguous.
    mutating func complete() -> [String] {
        let words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var wordStart = 0
        var wordIndex = 0
        for (index, word) in words.enumerated() {
            let wordEnd = wordStart + word.count
            if cursor <= wordEnd || index == words.count - 1 {
                wordIndex = index
                break
            }
            wordStart = wordEnd + 1
        }
        let prefix = words.indices.contains(wordIndex) ? words[wordIndex] : ""
        let matches = CommandCompleter.completions(words: words, wordIndex: wordIndex, prefix: prefix)
        guard !matches.isEmpty else { return [] }

        let completion: String
        if matches.count == 1 {
            completion = matches[0]
        } else {
            completion = matches.reduce(matches[0]) { commonPrefix, match in
                String(zip(commonPrefix, match).prefix { $0 == $1 }.map(\.0))
            }
        }
        guard completion.count > prefix.count else { return matches }

        var newWords = words
        newWords[wordIndex] = completion
        text = newWords.joined(separator: " ")
        cursor = newWords[0..<wordIndex].reduce(0) { $0 + $1.count + 1 } + completion.count
        return matches.count == 1 ? [] : matches
    }
}
