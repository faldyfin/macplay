import SwiftUI
import AppKit

@main
struct MacPlayApp: App {
    init() {
        // Set by VS Code-style editors for their child processes; when MacPlay is
        // started from such a terminal, Wine would pass it on to Windows programs
        // and every Electron-based launcher (TapTap…) would run as bare Node and quit.
        unsetenv("ELECTRON_RUN_AS_NODE")
        PlayTime.shared.start()
    }

    var body: some Scene {
        WindowGroup("MacPlay") {
            ContentView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1240, height: 780)
        // the dark theme runs to the top edge, like a game launcher
        .windowStyle(.hiddenTitleBar)
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case home
    case dashboard
    case steam
    case games
    case myGames
    case myApps
    var id: String { rawValue }
    var label: String {
        switch self {
        case .home: return L.t("Home", "Accueil", "Beranda")
        case .dashboard: return L.t("My Mac", "Ma machine", "Mac Saya")
        case .steam: return "Steam"
        case .games: return L.t("Compatible Games", "Jeux compatibles", "Game Kompatibel")
        case .myGames: return L.t("My Games", "Mes jeux", "Game Saya")
        case .myApps: return L.t("My Apps", "Mes apps", "App Saya")
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .dashboard: return "cpu"
        case .steam: return "cloud"
        case .games: return "gamecontroller"
        case .myGames: return WindowsApp.Category.game.icon
        case .myApps: return WindowsApp.Category.app.icon
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarSection = .home
    @AppStorage("lang") private var lang: String = AppLanguage.system.rawValue

    var body: some View {
        HStack(spacing: 0) {
            rail
            Group {
                switch selection {
                case .home: HomeView()
                case .dashboard: DashboardView()
                case .steam: SteamView()
                case .games: GamesView()
                // .id: a separate view state per section, so a selection never carries over
                case .myGames: AppsView(category: .game).id("myGames")
                case .myApps: AppsView(category: .app).id("myApps")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
        }
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .groupBoxStyle(CardBoxStyle())
        .onAppear {
            // no title bar to grab: let the window move by its background
            NSApp.windows.forEach { $0.isMovableByWindowBackground = true }
        }
        // re-create the whole tree when the language changes so every L.t()
        // call re-evaluates immediately, no relaunch needed
        .id(lang)
    }

    /// Icons only; the section name shows as a tooltip.
    private var rail: some View {
        VStack(spacing: 8) {
            ForEach(SidebarSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Image(systemName: section.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .foregroundStyle(selection == section ? .white : Theme.muted)
                        .background(selection == section ? Theme.accent : .clear,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(section.label)
                .accessibilityLabel(section.label)
            }
            Spacer()
            Menu {
                Picker(L.t("Language", "Langue", "Bahasa"), selection: $lang) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(Theme.muted)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(L.t("Language", "Langue", "Bahasa"))
        }
        // room for the window's traffic lights above the first icon
        .padding(.top, 40)
        .padding(.bottom, 16)
        .frame(width: 76)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
    }
}
