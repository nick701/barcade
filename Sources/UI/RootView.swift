import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 42))
                .foregroundStyle(.tint)

            Text("Barcade")
                .font(.largeTitle.bold())

            Text("Pick-up games from your menu bar.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
