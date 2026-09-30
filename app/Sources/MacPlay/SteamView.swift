import SwiftUI

struct SteamView: View {
    /// Last check, shown straight away when the tab is reopened while a fresh one runs.
    private static var lastStatus: SteamStatus?

    @State private var status: SteamStatus? = SteamView.lastStatus
    @State private var confirmUninstall = false
    @State private var confirmReinstall = false
    @State private var confirmStop = false
    @StateObject private var runner = ActionRunner()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Steam")
                    .font(.largeTitle.bold())

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

                if !runner.log.isEmpty {
                    LogPanel(runner: runner)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .task { await refresh() }
        .onChange(of: runner.running) { isRunning in
            if !isRunning { Task { await refresh() } }
        }
    }

    @ViewBuilder
    private func installedControls(_ status: SteamStatus) -> some View {
        if status.running {
            HStack {
                Label(L.t("Steam is running.", "Steam est en cours d'exécution."),
                      systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button(L.t("Stop Steam", "Arrêter Steam")) {
                    if Engine.downloadInProgress { confirmStop = true } else { stopSteam() }
                }
                .disabled(runner.running)
            }
            .confirmationDialog(
                L.t("Steam is downloading. Stopping it now can make Steam throw away what it has downloaded so far.",
                    "Steam télécharge. L'arrêter maintenant peut lui faire jeter ce qui est déjà téléchargé."),
                isPresented: $confirmStop, titleVisibility: .visible
            ) {
                Button(L.t("Stop anyway", "Arrêter quand même"), role: .destructive) { stopSteam() }
            }
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

    private func refresh() async {
        let fresh = await Task.detached(priority: .userInitiated) { Engine.steamStatus() }.value
        Self.lastStatus = fresh
        status = fresh
    }
}
