import ArgumentParser
import INDIMCPKit

struct FilterWheelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "filterwheel",
        abstract: "Control a rig's filter wheel.",
        subcommands: [Connect.self, Disconnect.self, Select.self]
    )

    struct RigOptions: ParsableArguments {
        @Option(name: .long, help: "The rig id.") var rig: String
    }

    struct Connect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "connect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.filterWheel(rigId: rigOptions.rig).connect()))
        }
    }

    struct Disconnect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "disconnect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.filterWheel(rigId: rigOptions.rig).disconnect()))
        }
    }

    struct Select: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "select")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @Argument(help: "The filter name to select.") var filter: String

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.filterWheel(rigId: rigOptions.rig).selectFilter(filter)
            Console.shared.print(describe(started))
        }
    }
}

struct FocuserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "focuser",
        abstract: "Control a rig's focuser.",
        subcommands: [Connect.self, Disconnect.self, SetPosition.self]
    )

    struct RigOptions: ParsableArguments {
        @Option(name: .long, help: "The rig id.") var rig: String
    }

    struct Connect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "connect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.focuser(rigId: rigOptions.rig).connect()))
        }
    }

    struct Disconnect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "disconnect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.focuser(rigId: rigOptions.rig).disconnect()))
        }
    }

    struct SetPosition: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "set-position")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @Argument(help: "The absolute focus position.") var position: Int

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.focuser(rigId: rigOptions.rig).setFocusPosition(position)
            Console.shared.print(describe(started))
        }
    }
}
