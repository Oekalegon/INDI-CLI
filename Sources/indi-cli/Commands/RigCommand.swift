import ArgumentParser
import INDIMCPKit

struct RigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rig",
        abstract: "List and inspect configured imaging rigs.",
        subcommands: [List.self, Show.self]
    )

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            for rig in try await client.listRigs() {
                Console.shared.print("\(rig.id)\t\(rig.name)")
            }
        }
    }

    struct Show: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "show")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The rig id.") var id: String

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let rig = try await client.getRig(id: id)
            Console.shared.print("\(rig.id): \(rig.name)")
            for component in rig.components {
                Console.shared.print("  \(component.role.rawValue) (\(component.id)): \(component.device ?? "no device assigned")")
            }
        }
    }
}
