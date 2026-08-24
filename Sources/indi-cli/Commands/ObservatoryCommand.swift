import ArgumentParser
import INDIMCPKit

struct ObservatoryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "observatory",
        abstract: "List and inspect configured observatory locations.",
        subcommands: [List.self, Show.self]
    )

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            for observatory in try await client.listObservatories() {
                Console.shared.print("\(observatory.id)\t\(observatory.name)")
            }
        }
    }

    struct Show: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "show")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The observatory id.") var id: String

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let observatory = try await client.getObservatory(id: id)
            Console.shared.print("\(observatory.id): \(observatory.name)")
            Console.shared.print("  lat \(observatory.latitudeDeg)°, lon \(observatory.longitudeDeg)°, elevation \(observatory.elevationMeters) m")
        }
    }
}
