import SwiftUI

@main
struct MacPlayApp: App {
    init() {
        // Set by VS Code-style editors for their child processes; when MacPlay is
        // started from such a terminal, Wine would pass it on to Windows programs
        // and every Electron-based launcher (TapTap…) would run as bare Node and quit.
        unsetenv("ELECTRON_RUN_AS_NODE")
    }

    var body: some Scene {
        WindowGroup("MacPlay") {
            ContentView()
                .frame(minWidth: 920, minHeight: 620)
        }
        .defaultSize(width: 1040, height: 680)
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case steam
    case games
    case myGames
    case myApps
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dashboard: return L.t("My Mac", "Ma machine", "Mac Saya")
        case .steam: return "Steam"
        case .games: return L.t("Compatible Games", "Jeux compatibles", "Game Kompatibel")
        case .myGames: return L.t("My Games", "Mes jeux", "Game Saya")
        case .myApps: return L.t("My Apps", "Mes apps", "App Saya")
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "cpu"
        case .steam: return "cloud"
        case .games: return "gamecontroller"
        case .myGames: return WindowsApp.Category.game.icon
        case .myApps: return WindowsApp.Category.app.icon
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarSection? = .dashboard
    @AppStorage("lang") private var lang: String = AppLanguage.system.rawValue

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(SidebarSection.allCases, selection: $selection) { section in
                    Label(section.label, systemImage: section.icon).tag(section)
                }
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "globe").foregroundStyle(.secondary)
                    Picker(L.t("Language", "Langue", "Bahasa"), selection: $lang) {
                        ForEach(AppLanguage.allCases) { l in
                            Text(l.label).tag(l.rawValue)
                        }
                    }
                    .labelsHidden()
                }
                .padding(10)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard: DashboardView()
            case .steam: SteamView()
            case .games: GamesView()
            // .id: a separate view state per section, so a selection never carries over
            case .myGames: AppsView(category: .game).id("myGames")
            case .myApps: AppsView(category: .app).id("myApps")
            }
        }
        // re-create the whole tree when the language changes so every L.t()
        // call re-evaluates immediately, no relaunch needed
        .id(lang)
    }
}
