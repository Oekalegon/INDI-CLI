import ArgumentParser

@main
struct IndiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "indi-cli",
        abstract: "Control an INDIMCP-server instance.",
        subcommands: [
            RigCommand.self,
            ObservatoryCommand.self,
            ServerCommand.self,
            MessagingCommand.self,
            MountCommand.self,
            CameraCommand.self,
            FilterWheelCommand.self,
            FocuserCommand.self,
            ScriptCommand.self,
            InteractiveCommand.self,
        ]
    )
}
