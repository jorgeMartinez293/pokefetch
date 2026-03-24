import Foundation
import AppKit

struct Pokemon: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let filename: String
    let url: URL
    let isGIF: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(filename) }
    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool { lhs.filename == rhs.filename }
}

class PokemonManager: ObservableObject {
    @Published var pokemons: [Pokemon] = []

    static let pokemonsDir: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/fastfetch/pokemons")
    }()

    init() { reload() }

    func reload() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: Self.pokemonsDir, includingPropertiesForKeys: nil
        ) else { return }

        let valid = Set(["gif", "png", "jpg", "jpeg", "webp"])
        pokemons = files
            .filter { valid.contains($0.pathExtension.lowercased()) }
            .map { url in
                let filename = url.lastPathComponent
                let name = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                    .capitalized
                return Pokemon(name: name, filename: filename, url: url,
                               isGIF: url.pathExtension.lowercased() == "gif")
            }
            .sorted { $0.name < $1.name }
    }
}
