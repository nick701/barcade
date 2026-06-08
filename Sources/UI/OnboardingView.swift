import SwiftUI

enum OnboardingStep: Int, CaseIterable, Equatable {
    case games
    case navigation
    case quickAccess

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var title: String {
        switch self {
        case .games: "Pick a game"
        case .navigation: "Scores and settings"
        case .quickAccess: "Keep Barcade close"
        }
    }

    var detail: String {
        switch self {
        case .games:
            "Choose any enabled game from the grid. Your current game stays paused when Barcade closes."
        case .navigation:
            "Use the top tabs to review high scores, enable games, and drag them into your preferred order."
        case .quickAccess:
            "Pin Barcade as a floating window or press ⌥G anywhere to open and close it."
        }
    }

    var symbolName: String {
        switch self {
        case .games: "gamecontroller.fill"
        case .navigation: "slider.horizontal.3"
        case .quickAccess: "pin.fill"
        }
    }
}

struct OnboardingView: View {
    let step: OnboardingStep
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)

            VStack(spacing: 12) {
                Image(systemName: "arrow.up")
                    .font(.title2.bold())
                    .foregroundStyle(.tint)

                Image(systemName: step.symbolName)
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)

                Text(step.title)
                    .font(.title2.bold())

                Text(step.detail)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { item in
                        Capsule()
                            .fill(item == step ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: item == step ? 20 : 7, height: 7)
                    }
                }

                HStack {
                    Button("Skip", action: onSkip)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(step.next == nil ? "Start Playing" : "Next", action: onNext)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 340)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 18)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: cardAlignment
            )
            .padding(.horizontal, 18)
            .padding(.top, 58)
            .padding(.bottom, 22)
        }
    }

    private var cardAlignment: Alignment {
        switch step {
        case .games: .topLeading
        case .navigation: .top
        case .quickAccess: .topTrailing
        }
    }
}
