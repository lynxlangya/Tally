import SwiftUI

struct AppRootView: View {
    private let sampleAmount = Money(cents: 428560)
    private let sampleDayKey = DayKeyFormatter.dayKey(for: Date())

    var body: some View {
        VStack(spacing: 12) {
            Text("JustOne")
                .font(.title)
            Text(MoneyFormatter.string(from: sampleAmount))
                .font(.headline)
            Text(sampleDayKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    AppRootView()
}
