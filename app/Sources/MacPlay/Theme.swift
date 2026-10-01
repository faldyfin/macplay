import SwiftUI

/// The game-launcher look: deep maroon surfaces and a single coral accent.
/// Corner radii follow hierarchy: hero 22, cards 16, chips 10.
enum Theme {
    static let background = Color(hex: 0x2A0F14)
    static let panel = Color(hex: 0x3A161D)
    static let card = Color(hex: 0x4C1F28)
    static let accent = Color(hex: 0xFF6B5E)
    static let text = Color(hex: 0xF7ECE9)
    static let muted = Color(hex: 0xC7A5A2)
    /// Rating stars only.
    static let star = Color(hex: 0xFFB547)

    /// Screen titles, the greeting and game names on artwork.
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Draws every GroupBox in the app as a theme card, so existing screens take the
/// look without being rewritten.
struct CardBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.headline)
                .foregroundStyle(Theme.text)
            configuration.content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A short state label (installed, running, a rating).
struct Chip: View {
    let text: String
    var color: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Stand-in for missing artwork: the title on a warm gradient.
struct ArtPlaceholder: View {
    let title: String

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.card, Theme.accent.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(title)
                .font(Theme.title(16))
                .foregroundStyle(Theme.text.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(12)
        }
    }
}
