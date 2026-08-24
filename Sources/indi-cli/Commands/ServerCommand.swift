import ArgumentParser
import INDIMCPKit

struct ServerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "server",
        abstract: "Control the managed indiserver process.",
        subcommands: [Status.self, Start.self, Stop.self, Restart.self]
    )

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "status")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.getINDIServerStatus()
            Console.shared.print(status.running ? "running on port \(status.port)" : "stopped")
        }
    }

    struct Start: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "start")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Option(help: "Port for indiserver to listen on.") var port: Int = defaultINDIServerPort

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.startINDIServer(port: port)
            Console.shared.print("started on port \(status.port)")
        }
    }

    struct Stop: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "stop")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            _ = try await client.stopINDIServer()
            Console.shared.print("stopped")
        }
    }

    struct Restart: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "restart")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Option(help: "Port for indiserver to listen on; keeps the current port if omitted.")
        var port: Int?

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.restartINDIServer(port: port)
            Console.shared.print("restarted on port \(status.port)")
        }
    }
}

struct MessagingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "messaging",
        abstract: "Control the INDI property/message event stream.",
        subcommands: [Status.self, Start.self, Stop.self]
    )

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "status")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.getINDIMessagingStatus()
            Console.shared.print(status.running ? "running (\(status.host):\(status.port))" : "stopped")
        }
    }

    struct Start: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "start")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Option(help: "INDI server host.") var host: String = "localhost"
        @Option(help: "INDI server port.") var port: Int = defaultINDIServerPort

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.startINDIMessaging(host: host, port: port)
            Console.shared.print("started (\(status.host):\(status.port))")
        }
    }

    struct Stop: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "stop")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            _ = try await client.stopINDIMessaging()
            Console.shared.print("stopped")
        }
    }
}
