import Testing

@testable import indi_cli

@Suite struct CommandCompleterTests {
    @Test func completesRootCommandPrefix() {
        let matches = CommandCompleter.completions(words: ["mo"], wordIndex: 0, prefix: "mo")
        #expect(matches == ["mount"])
    }

    @Test func completesSubcommandPrefix() {
        let matches = CommandCompleter.completions(words: ["camera", "coo"], wordIndex: 1, prefix: "coo")
        #expect(matches.sorted() == ["cool", "cooler-off", "cooler-on"])
    }
}
