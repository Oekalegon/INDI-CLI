import ArgumentParser

/// Launches the split-pane interactive shell: a scrolling message pane above a persistent,
/// tab-completing input line. `listen [device]` starts streaming live INDI messages into the
/// pane; `filter <text>` narrows what's shown; a command just run has its device's stream lines
/// drawn highlighted so it doesn't get lost in an active stream. Every plain-CLI subcommand
/// (`mount slew --rig ...`, `camera capture --rig ...`, etc.) works unmodified inside the shell.
struct InteractiveCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "interactive")
    @OptionGroup var endpointOptions: ClientEndpointOptions

    func run() async throws {
        await InteractiveSession(endpointOptions: endpointOptions).run()
    }
}
