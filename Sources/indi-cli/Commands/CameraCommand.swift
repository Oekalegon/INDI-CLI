import ArgumentParser
import INDIMCPKit

struct CameraCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "camera",
        abstract: "Control a rig's camera.",
        subcommands: [
            Connect.self, Disconnect.self, CoolerOn.self, CoolerOff.self, Cool.self,
            Capture.self, CaptureDarks.self, CaptureBias.self, CaptureFlats.self, CaptureLights.self,
        ]
    )

    struct RigOptions: ParsableArguments {
        @Option(name: .long, help: "The rig id.") var rig: String
    }

    struct GainOffsetOptions: ParsableArguments {
        @Option(help: "Camera gain.") var gain: Double?
        @Option(help: "Camera offset.") var offset: Double?
    }

    struct Connect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "connect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.camera(rigId: rigOptions.rig).connect()))
        }
    }

    struct Disconnect: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "disconnect")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.camera(rigId: rigOptions.rig).disconnect()))
        }
    }

    struct CoolerOn: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "cooler-on")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.camera(rigId: rigOptions.rig).coolerOn()))
        }
    }

    struct CoolerOff: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "cooler-off")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            Console.shared.print(describe(try await client.camera(rigId: rigOptions.rig).coolerOff()))
        }
    }

    struct Cool: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "cool")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @Option(help: "Target temperature in Celsius.") var targetTempC: Double = -10
        @Option(help: "Seconds to wait for the temperature to stabilize.") var timeoutSeconds: Double = 300

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig)
                .coolCamera(targetTempC: targetTempC, timeoutSeconds: timeoutSeconds)
            Console.shared.print(describe(started))
        }
    }

    struct Capture: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "capture")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @OptionGroup var gainOffset: GainOffsetOptions
        @Option(help: "Exposure length in seconds.") var exposureSeconds: Double
        @Option(help: "Frame type: light, dark, flat, or bias.") var frameType: FrameType = .light
        @Option(help: "Horizontal binning.") var binningX: Int = 1
        @Option(help: "Vertical binning.") var binningY: Int = 1

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig).captureFrame(
                exposureSeconds: exposureSeconds,
                frameType: frameType,
                binningX: binningX,
                binningY: binningY,
                gain: gainOffset.gain,
                offset: gainOffset.offset
            )
            Console.shared.print(describe(started))
        }
    }

    struct CaptureDarks: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "capture-darks")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @OptionGroup var gainOffset: GainOffsetOptions
        @Option(help: "Exposure length in seconds.") var exposureSeconds: Double
        @Option(help: "Number of frames to capture.") var count: Int
        @Option(help: "Target temperature in Celsius.") var targetTempC: Double = -10

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig).captureDarkSequence(
                exposureSeconds: exposureSeconds,
                count: count,
                targetTempC: targetTempC,
                gain: gainOffset.gain,
                offset: gainOffset.offset
            )
            Console.shared.print(describe(started))
        }
    }

    struct CaptureBias: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "capture-bias")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @OptionGroup var gainOffset: GainOffsetOptions
        @Option(help: "Number of frames to capture.") var count: Int

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig).captureBiasSequence(
                count: count,
                gain: gainOffset.gain,
                offset: gainOffset.offset
            )
            Console.shared.print(describe(started))
        }
    }

    struct CaptureFlats: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "capture-flats")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @OptionGroup var gainOffset: GainOffsetOptions
        @Option(help: "Filter name to select before capturing.") var filter: String
        @Option(help: "Focuser position to move to before capturing.") var focusPosition: Int
        @Option(help: "Exposure length in seconds.") var exposureSeconds: Double
        @Option(help: "Number of frames to capture.") var count: Int

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig).captureFlatSequence(
                filterName: filter,
                focusPosition: focusPosition,
                exposureSeconds: exposureSeconds,
                count: count,
                gain: gainOffset.gain,
                offset: gainOffset.offset
            )
            Console.shared.print(describe(started))
        }
    }

    struct CaptureLights: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "capture-lights")
        @OptionGroup var endpointOptions: ClientEndpointOptions
        @OptionGroup var rigOptions: RigOptions
        @OptionGroup var gainOffset: GainOffsetOptions
        @Option(help: "Right ascension, in hours.") var ra: Double
        @Option(help: "Declination, in degrees.") var dec: Double
        @Option(help: "Filter name to select before capturing.") var filter: String
        @Option(help: "Focuser position to move to before capturing.") var focusPosition: Int
        @Option(help: "Exposure length in seconds.") var exposureSeconds: Double
        @Option(help: "Number of frames to capture.") var count: Int
        @Option(help: "Object name for FITS headers.") var object: String?
        @Option(help: "Target temperature in Celsius.") var targetTempC: Double = -10

        func run() async throws {
            let client = try await endpointOptions.connectedClient()
            defer { Task { await client.disconnect() } }
            let started = try await client.camera(rigId: rigOptions.rig).captureLightSequence(
                ra: ra,
                dec: dec,
                filterName: filter,
                focusPosition: focusPosition,
                exposureSeconds: exposureSeconds,
                count: count,
                objectName: object,
                targetTempC: targetTempC,
                gain: gainOffset.gain,
                offset: gainOffset.offset
            )
            Console.shared.print(describe(started))
        }
    }
}

extension FrameType: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument.prefix(1).uppercased() + argument.dropFirst().lowercased())
    }
}
