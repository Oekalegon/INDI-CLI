import ArgumentParser
import INDIMCPKit

struct MountCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mount",
        abstract: "Control a rig's mount.",
        subcommands: [Connect.self, Disconnect.self, Park.self, Unpark.self, Slew.self, TrackOff.self, TrackMode.self]
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
            let started = try await client.mount(rigId: rigOptions.rig).connect()
            Console.shared.print(describe(started))
        }
    }

    struct Disconnect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "disconnect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).disconnect()
            Console.shared.print(describe(started))
        }
    }

    struct Park: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "park")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).park()
            Console.shared.print(describe(started))
        }
    }

    struct Unpark: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "unpark")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).unpark()
            Console.shared.print(describe(started))
        }
    }

    struct Slew: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "slew")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @Option(help: "Right ascension, in hours.") var ra: Double
        @Option(help: "Declination, in degrees.") var dec: Double

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).slew(ra: ra, dec: dec)
            Console.shared.print(describe(started))
        }
    }

    struct TrackOff: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "track-off")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).trackOff()
            Console.shared.print(describe(started))
        }
    }

    struct TrackMode: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "track-mode")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @Argument(help: "The track-mode switch element name.") var mode: String

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.mount(rigId: rigOptions.rig).setTrackMode(mode)
            Console.shared.print(describe(started))
        }
    }
}
