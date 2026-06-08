import SwiftUI

struct RootView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var scoreStore: ScoreStore
    @ObservedObject var pauseManager: PauseManager

    @State private var section = RootSection.games
    @State private var selectedGame: GameMetadata?
    @State private var onboardingStep: OnboardingStep?
    @State private var didCheckOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            if let selectedGame {
                GameHostView(
                    game: selectedGame,
                    settingsStore: settingsStore,
                    scoreStore: scoreStore,
                    pauseManager: pauseManager,
                    onBack: { self.selectedGame = nil }
                )
            } else {
                HStack(spacing: 10) {
                    Picker("Section", selection: $section) {
                        ForEach(RootSection.allCases) { section in
                            Label(section.title, systemImage: section.symbolName)
                                .tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Button {
                        try? settingsStore.setFloatingWindow(
                            !settingsStore.settings.floatingWindow
                        )
                    } label: {
                        Image(
                            systemName: settingsStore.settings.floatingWindow
                                ? "pin.slash"
                                : "pin"
                        )
                    }
                    .help(
                        settingsStore.settings.floatingWindow
                            ? "Return to menu bar"
                            : "Open as floating window"
                    )
                }
                .padding()

                Group {
                    switch section {
                    case .games:
                        GamePickerView(
                            games: GameCatalog.enabledGames(for: settingsStore.settings),
                            onSelect: { selectedGame = $0 }
                        )
                    case .scores:
                        HighScoresView(scoreStore: scoreStore)
                    case .settings:
                        SettingsView(
                            settingsStore: settingsStore,
                            scoreStore: scoreStore
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 460, height: 600)
        .background(.regularMaterial)
        .overlay {
            if let onboardingStep {
                OnboardingView(
                    step: onboardingStep,
                    onNext: advanceOnboarding,
                    onSkip: completeOnboarding
                )
            }
        }
        .onAppear {
            guard !didCheckOnboarding else {
                return
            }
            didCheckOnboarding = true
            if !settingsStore.settings.hasCompletedOnboarding {
                onboardingStep = .games
            }
        }
    }

    private func advanceOnboarding() {
        if let next = onboardingStep?.next {
            onboardingStep = next
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        try? settingsStore.setOnboardingCompleted(true)
        onboardingStep = nil
    }
}

private enum RootSection: String, CaseIterable, Identifiable {
    case games
    case scores
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .games: "Games"
        case .scores: "Scores"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .games: "gamecontroller"
        case .scores: "trophy"
        case .settings: "gearshape"
        }
    }
}

struct StorageErrorView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Label("Barcade could not start", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        }
        .frame(width: 460, height: 600)
    }
}
