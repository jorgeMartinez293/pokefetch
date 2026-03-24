import SwiftUI

struct ContentView: View {
    @StateObject private var pokemonManager = PokemonManager()
    @State private var config         = ConfigManager.load()
    @State private var selectedPokemon: Pokemon?
    @State private var isRandomMode   = false
    @State private var searchText     = ""
    @State private var saveStatus     = SaveStatus.idle
    @State private var isOnBattery    = ConfigManager.isOnBattery()
    @State private var accentColor    = Color(red: 0.85, green: 0.55, blue: 0.55)

    enum SaveStatus { case idle, saved, error }

    var body: some View {
        HSplitView {
            PokemonGridView(
                pokemons: pokemonManager.pokemons,
                selectedPokemon: $selectedPokemon,
                isRandomMode: $isRandomMode,
                searchText: $searchText,
                accentColor: accentColor
            )
            .frame(minWidth: 240, idealWidth: 270, maxWidth: 330)

            VStack(spacing: 0) {
                PreviewView(
                    pokemon: isRandomMode ? pokemonManager.pokemons.randomElement() : selectedPokemon,
                    displayMode: config.displayMode,
                    isOnBattery: isOnBattery
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                SettingsBar(
                    config: $config,
                    selectedPokemon: isRandomMode ? nil : selectedPokemon,
                    isRandom: isRandomMode,
                    saveStatus: saveStatus,
                    accentColor: accentColor,
                    onSave: saveConfig
                )
            }
        }
        .onAppear {
            if config.selectedPokemon == nil {
                isRandomMode = true
                accentColor  = Color(red: 0.85, green: 0.55, blue: 0.55)
            } else if let saved = config.selectedPokemon,
                      let poke  = pokemonManager.pokemons.first(where: { $0.filename == saved }) {
                selectedPokemon = poke
                computeColor(for: poke)
            }
        }
        .onChange(of: selectedPokemon) { poke in
            if let poke { computeColor(for: poke) }
        }
        .onChange(of: isRandomMode) { random in
            if random { accentColor = Color(red: 0.85, green: 0.55, blue: 0.55) }
        }
    }

    // MARK: - Actions

    private func computeColor(for poke: Pokemon) {
        DispatchQueue.global(qos: .userInitiated).async {
            let color = ColorExtractor.dominantColor(for: poke.url)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.35)) { accentColor = color }
            }
        }
    }

    private func saveConfig() {
        config.selectedPokemon = isRandomMode ? nil : selectedPokemon?.filename
        do {
            try ConfigManager.save(config)
            withAnimation { saveStatus = .saved }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saveStatus = .idle }
            }
        } catch {
            withAnimation { saveStatus = .error }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { saveStatus = .idle }
            }
        }
    }
}
