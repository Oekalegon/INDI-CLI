import ArgumentParser
import INDIMCPKit
import MCP

struct ScriptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "script",
        abstract: "List, run, and control INDIMCP-server scripts.",
        subcommands: [List.self, Run.self, Status.self, Cancel.self, Pause.self, Resume.self]
    )

    /// Parses a `key=value` command-line pair into a `Value`, inferring int/double/bool from the
    /// raw text and falling back to `.string` — good enough for the scalar script parameters
    /// every built-in script declares (see `Parameter`/`ParameterType`), without pulling in a
    /// full JSON-literal syntax for the common case.
    struct ParamOption: ExpressibleByArgument {
        let key: String
        let value: Value

        init?(argument: String) {
            guard let separatorIndex = argument.firstIndex(of: "=") else { return nil }
            key = String(argument[argument.startIndex..<separatorIndex])
            let rawValue = String(argument[argument.index(after: separatorIndex)...])
            if let intValue = Int(rawValue) {
                value = .int(intValue)
            } else if let doubleValue = Double(rawValue) {
                value = .double(doubleValue)
            } else if let boolValue = Bool(rawValue) {
                value = .bool(boolValue)
            } else {
                value = .string(rawValue)
            }
        }
    }

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list")
        @OptionGroup var endpointOptions: ClientEndpointOptions

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            for script in try await client.listScripts() {
                Console.shared.print("\(script.id)\t\(script.name)\t\(script.description ?? "")")
            }
        }
    }

    struct Run: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "run")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The script id.") var scriptId: String
        @Option(name: .long, help: "The rig id to run against.") var rig: String
        @Option(name: .long, help: "A script parameter as key=value; repeat for more.")
        var param: [ParamOption] = []
        @Option(help: "A saved observatory id for celestial-context FITS headers.")
        var location: String?

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            var parameters: [String: Value] = [:]
            for pair in param {
                parameters[pair.key] = pair.value
            }
            let started = try await client.runScript(
                scriptId: scriptId,
                rigId: rig,
                parameters: parameters.isEmpty ? nil : parameters,
                locationId: location
            )
            Console.shared.print(describe(started))
        }
    }

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "status")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The run id.") var runId: String
        @Flag(help: "Poll until the run reaches a terminal status.") var wait: Bool = false

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = wait
                ? try await client.waitForTerminalStatus(runId: runId)
                : try await client.getScriptStatus(runId: runId)
            Console.shared.print(describe(status))
        }
    }

    struct Cancel: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "cancel")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The run id.") var runId: String

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let status = try await client.cancelScript(runId: runId)
            Console.shared.print(describe(status))
        }
    }

    struct Pause: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "pause")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The run id.") var runId: String

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let outcome = try await client.pauseScript(runId: runId)
            Console.shared.print(describe(outcome))
        }
    }

    struct Resume: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "resume")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @Argument(help: "The run id.") var runId: String

        func run() async throws {
            let client = try endpointOptions.makeClient()
            try await client.connect()
            defer { Task { await client.disconnect() } }
            let outcome = try await client.resumeScript(runId: runId)
            Console.shared.print(describe(outcome))
        }
    }
}
