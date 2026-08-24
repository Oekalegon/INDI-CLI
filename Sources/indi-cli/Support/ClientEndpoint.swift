import ArgumentParser
import Foundation
import INDIMCPKit

/// Shared `--endpoint` option, resolved against `INDI_MCP_ENDPOINT` when not passed explicitly —
/// every subcommand mixes this in rather than re-declaring the option and its default.
struct ClientEndpointOptions: ParsableArguments {
    @Option(name: .long, help: "INDIMCP-server Streamable HTTP endpoint.")
    var endpoint: String = ProcessInfo.processInfo.environment["INDI_MCP_ENDPOINT"] ?? "http://127.0.0.1:8000/mcp"

    func makeClient() throws -> INDIMCPClient {
        guard let url = URL(string: endpoint) else {
            throw ValidationError("'\(endpoint)' isn't a valid URL.")
        }
        return INDIMCPClient(endpoint: url, clientName: "indi-cli", clientVersion: "0.1.0")
    }

    /// Connects and makes sure the INDI server and messaging stream are up, matching
    /// `INDIMCPKitTestApp`'s `ensureINDIServerAndMessagingRunning` — device commands otherwise
    /// fail with a confusing error rather than a clear "server not running" one.
    func connectedClient() async throws -> INDIMCPClient {
        let client = try makeClient()
        try await client.connect()
        let serverStatus = try await client.getINDIServerStatus()
        if !serverStatus.running {
            _ = try await client.startINDIServer()
        }
        let messagingStatus = try await client.getINDIMessagingStatus()
        if !messagingStatus.running {
            _ = try await client.startINDIMessaging()
        }
        return client
    }
}
