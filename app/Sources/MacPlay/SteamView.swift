import SwiftUI

struct SteamView: View {
    /// Last check, shown straight away when the tab is reopened while a fresh one runs.
    private static var lastStatus: SteamStatus?

    @State private var status: SteamStatus? = SteamView.lastStatus
    @State private var confirmUninstall = false
    @State private var confirmReinstall = false
    @State private var confirmStop = false
    /// Set by Launch until Steam's window is up, so the button can't be pressed twice.
    @State private var launchStarted: Date?
    @StateObject private var runner = ActionRunner()
    // installed Steam games and what their pages need
    @State private var games: [InstalledGame] = []
    @State private var stats: [String: ReportStats] = [:]
    @State private var knownGames: [String: GameEntry] = [:]
    @State private var profile: HardwareProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Steam")
                            .font(.largeTitle.bold())
                        Spacer()
                        if let status, status.installed {
                            launchOrStop(status)
                        }
                    }

                    GroupBox(L.t("Windows Steam", "Steam Windows")) {
                        VStack(alignment: .leading, spacing: 10) {
                            if let status {
                                if status.installed {
                                    installedControls(status)
                                } else {
                                    notInstalledControls
                                }
                            } else {
                                HStack(spacing: 8) {
                                    ProgressView().controlSize(.small)
                                    Text(L.t("Checking Steam…", "Vérification de Steam…"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }

                    if status?.installed == true {
                        gamesBox
                    }

                    if !runner.log.isEmpty {
                        LogPanel(runner: runner)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .navigationDestination(for: InstalledGame.self) { game in
                InstalledDetail(game: game, known: knownGames[game.appid], stats: stats[game.appid],
                                profile: profile) { newStats in
                    if let newStats { stats[game.appid] = newStats }
                }
            }
        }
        .task {
            await loadGames()
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await refresh()
            }
        }
        .onChange(of: runner.running) { isRunning in
            if !isRunning { Task { await refresh() } }
        }
    }

    @ViewBuilder
    private func launchOrStop(_ status: SteamStatus) -> some View {
        if status.running {
            Button {
                if Engine.downloadInProgress { confirmStop = true } else { stopSteam() }
            } label: {
                Label(L.t("Stop", "Arrêter"), systemImage: "stop.fill")
            }
            .controlSize(.large)
            .disabled(runner.running)
            .confirmationDialog(
                L.t("Steam is downloading. Stopping it now can make Steam throw away what it has downloaded so far.",
                    "Steam télécharge. L'arrêter maintenant peut lui faire jeter ce qui est déjà téléchargé."),
                isPresented: $confirmStop, titleVisibility: .visible
            ) {
                Button(L.t("Stop anyway", "Arrêter quand même"), role: .destructive) { stopSteam() }
            }
        } else if launchStarted != nil {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(L.t("Starting Steam…", "Démarrage de Steam…")).foregroundStyle(.secondary)
            }
        } else {
            Button {
                launchStarted = Date()
                Task.detached(priority: .userInitiated) { Engine.launchSteam() }
            } label: {
                Label(L.t("Launch", "Lancer"), systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(runner.running)
        }
    }

    @ViewBuilder
    private func installedControls(_ status: SteamStatus) -> some View {
        if status.running {
            Label(L.t("Steam is running.", "Steam est en cours d'exécution."),
                  systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Label(L.t("Steam is installed.", "Steam est installé."),
                  systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        Text(L.t("Engine: ", "Moteur : ") + (status.engineVersion ?? "?")
             + L.t(" — graphics: ", " — graphismes : ") + status.backend)
            .font(.caption)
            .foregroundStyle(.secondary)
        Text(L.t("Steam updates itself when it launches — that's normal. Let the update finish before playing.",
                 "Steam se met à jour à son lancement — c'est normal. Laisse la mise à jour se terminer avant de jouer."))
            .font(.caption)
            .foregroundStyle(.secondary)
        HStack {
            Button(L.t("Restart Steam cleanly", "Relancer Steam proprement")) {
                runner.start(L.t("Restarting the Steam session", "Redémarrage de la session Steam"),
                             Engine.restart)
            }
            .disabled(runner.running)
            Text(L.t("Do this after any configuration change.",
                     "À faire après tout changement de configuration."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        HStack {
            Button(L.t("Reinstall Steam…", "Réinstaller Steam…")) { confirmReinstall = true }
                .disabled(runner.running)
            Button(role: .destructive) { confirmUninstall = true } label: {
                Text(L.t("Uninstall Steam…", "Désinstaller Steam…"))
            }
            .disabled(runner.running)
        }
        .confirmationDialog(
            L.t("Reinstall Steam from scratch? Installed games will be deleted too.",
                "Réinstaller Steam de zéro ? Les jeux installés seront aussi supprimés."),
            isPresented: $confirmReinstall, titleVisibility: .visible
        ) {
            Button(L.t("Reinstall everything", "Tout réinstaller"), role: .destructive) {
                runner.start(L.t("Full reinstall", "Réinstallation complète"), Engine.reinstallSteam)
            }
        }
        .confirmationDialog(
            L.t("Uninstall Steam? The wrapper AND all games installed inside will be deleted.",
                "Désinstaller Steam ? Le wrapper ET tous les jeux installés dedans seront supprimés."),
            isPresented: $confirmUninstall, titleVisibility: .visible
        ) {
            Button(L.t("Uninstall everything", "Tout désinstaller"), role: .destructive) {
                runner.start(L.t("Uninstalling Steam", "Désinstallation de Steam"), Engine.uninstallSteam)
            }
        }
    }

    private var notInstalledControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L.t("Steam is not installed yet.", "Steam n'est pas encore installé."),
                  systemImage: "exclamationmark.circle")
                .foregroundStyle(.orange)
            HStack {
                Button(L.t("Install Steam (~450 MB)", "Installer Steam (~450 Mo)")) {
                    runner.start(L.t("Full Steam installation", "Installation complète de Steam"),
                                 Engine.setupSteam)
                }
                .buttonStyle(.borderedProminent)
                .disabled(runner.running)
                Text(L.t("10-15 minutes. Fully automatic.", "10 à 15 minutes. Tout est automatique."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stopSteam() {
        runner.start(L.t("Stopping Steam", "Arrêt de Steam"), Engine.stopSteam)
    }

    private var gamesBox: some View {
        GroupBox(L.t("Installed games", "Jeux installés")) {
            VStack(alignment: .leading, spacing: 0) {
                if games.isEmpty {
                    Text(L.t("No games installed yet. Install one in Steam, or from Compatible Games.",
                             "Aucun jeu installé. Installes-en un dans Steam, ou depuis Jeux compatibles."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                ForEach(games) { game in
                    NavigationLink(value: game) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.name).lineLimit(1)
                                HStack(spacing: 6) {
                                    if game.sizeGB > 0.05 {
                                        Text(String(format: "%.1f \(L.t("GB", "Go"))", game.sizeGB))
                                    }
                                    if let s = stats[game.appid] {
                                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                                        Text(String(format: "%.1f (%d)", s.avg_rating, s.report_count))
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if game.id != games.last?.id { Divider() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    /// Games finish installing while Steam runs: read the list on open and whenever Steam stops.
    private func loadGames() async {
        games = SteamLibrary.installedGames()
        // the list is downloaded: a duplicate Steam id must not crash the app
        knownGames = Dictionary(Engine.loadGames().compactMap { g in g.steam_appid.map { (String($0), g) } },
                                uniquingKeysWith: { first, _ in first })
        if profile == nil { profile = await Task.detached { Engine.detect() }.value }
        stats = await Hub.fetchStats(appids: games.map(\.appid))
    }

    private func refresh() async {
        let fresh = await Task.detached(priority: .userInitiated) { Engine.steamStatus() }.value
        let stopped = status?.running == true && !fresh.running
        Self.lastStatus = fresh
        status = fresh
        if stopped { await loadGames() }
        // cold starts (first launch, self-update) can take minutes
        if fresh.running || (launchStarted.map { Date().timeIntervalSince($0) > 180 } ?? false) {
            launchStarted = nil
        }
    }
}
