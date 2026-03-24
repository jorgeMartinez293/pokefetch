import Foundation

enum DisplayMode: String, Codable, CaseIterable {
    case gif   = "gif"
    case image = "image"
    case auto  = "auto"

    var label: String {
        switch self {
        case .gif:   return "GIF"
        case .image: return "Imagen"
        case .auto:  return "Auto (batería)"
        }
    }
    var icon: String {
        switch self {
        case .gif:   return "play.circle"
        case .image: return "photo"
        case .auto:  return "bolt.badge.automatic"
        }
    }
}

struct PokefetchConfig: Codable {
    var selectedPokemon: String?
    var displayMode: DisplayMode

    enum CodingKeys: String, CodingKey {
        case selectedPokemon = "selected_pokemon"
        case displayMode     = "display_mode"
    }
    init(selectedPokemon: String? = nil, displayMode: DisplayMode = .auto) {
        self.selectedPokemon = selectedPokemon
        self.displayMode     = displayMode
    }
}

class ConfigManager {
    static let configURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/fastfetch/pokefetch_config.json")
    }()

    static func load() -> PokefetchConfig {
        guard let data = try? Data(contentsOf: configURL),
              let cfg  = try? JSONDecoder().decode(PokefetchConfig.self, from: data)
        else { return PokefetchConfig() }
        return cfg
    }

    static func save(_ config: PokefetchConfig) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        let data = try enc.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    static func isOnBattery() -> Bool {
        shell("pmset -g batt 2>/dev/null | head -n 1").contains("Battery Power")
    }

    @discardableResult
    static func shell(_ cmd: String) -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments  = ["-c", cmd]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? ""
    }
}
