import SwiftUI

/// Runs one long engine action at a time and exposes its live log.
final class ActionRunner: ObservableObject {
    @Published var log: [String] = []
    @Published var running = false
    @Published var lastExit: Int32? = nil

    func start(_ label: String,
               _ op: @escaping (_ emit: @escaping (String) -> Void, _ done: @escaping (Int32) -> Void) -> Void) {
        guard !running else { return }
        running = true
        lastExit = nil
        log = ["▶ " + label]
        op({ line in
            DispatchQueue.main.async { self.log.append(line) }
        }, { code in
            DispatchQueue.main.async {
                self.running = false
                self.lastExit = code
                self.log.append(code == 0 ? L.t("✓ Done", "✓ Terminé", "✓ Selesai") : L.t("✗ Failed (\(code))", "✗ Échec (\(code))", "✗ Gagal (\(code))"))
            }
        })
    }
}

struct DashboardView: View {
    /// Last check, shown straight away when the tab is reopened while a fresh one runs.
    private static var lastReport: DoctorReport?

    @State private var report: DoctorReport? = DashboardView.lastReport
    @State private var screens = GameDisplay.screens()
    @State private var rearranged = GameDisplay.isRearranged
    @AppStorage(GameDisplay.preferenceKey) private var gameDisplay = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L.t("My Mac", "Ma machine", "Mac Saya"))
                    .font(.largeTitle.bold())

                if let r = report {
                    HStack(spacing: 12) {
                        StatCard(title: L.t("Chip", "Puce", "Chip"), value: r.profile.chip)
                        StatCard(title: L.t("Memory", "Mémoire", "Memori"), value: "\(r.profile.ramGB) \(L.t("GB", "Go", "GB"))")
                        StatCard(title: "GPU", value: r.profile.gpuCores.map { "\($0) \(L.t("cores", "cœurs", "core"))" } ?? "—")
                        StatCard(title: "macOS", value: r.profile.macosVersion)
                    }

                    GroupBox(L.t("System health", "État du système", "Kesehatan sistem")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HealthRow(ok: r.profile.appleSilicon,
                                      text: r.profile.appleSilicon
                                        ? L.t("Apple Silicon detected", "Apple Silicon détecté", "Apple Silicon terdeteksi")
                                        : L.t("Intel Mac: performance will be poor", "Mac Intel : performances médiocres", "Mac Intel: performanya akan buruk"))
                            HealthRow(ok: r.profile.rosetta,
                                      text: r.profile.rosetta
                                        ? L.t("Rosetta 2 installed", "Rosetta 2 installé", "Rosetta 2 terinstal")
                                        : L.t("Rosetta 2 missing (required)", "Rosetta 2 manquant (requis)", "Rosetta 2 belum ada (wajib)"))
                            HealthRow(ok: !r.swapSaturated,
                                      text: String(format: L.t("Swap: %.1f / %.1f GB used", "Swap : %.1f / %.1f Go utilisés", "Swap: %.1f / %.1f GB terpakai"),
                                                   r.swapUsedGB, r.swapTotalGB)
                                        + (r.swapSaturated
                                            ? L.t(" — close some apps before playing (main cause of lag)",
                                                  " — ferme des apps avant de jouer (cause n°1 de lag)",
                                                  " — tutup beberapa app sebelum main (penyebab utama lag)")
                                            : ""))
                            HealthRow(ok: r.diskFreeGB > 30,
                                      text: String(format: L.t("Disk: %.0f GB free", "Disque : %.0f Go libres", "Disk: %.0f GB kosong"), r.diskFreeGB))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }
                } else {
                    ProgressView().controlSize(.small)
                }

                if screens.count > 1 {
                    gameScreenBox
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .task {
            let fresh = await Task.detached(priority: .userInitiated) { Engine.doctor() }.value
            Self.lastReport = fresh
            report = fresh
        }
        // screens plugged in or out, or rearranged (by MacPlay too)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = GameDisplay.screens()
            rearranged = GameDisplay.isRearranged
        }
    }

    private var gameScreenBox: some View {
        GroupBox(L.t("Screen for games", "Écran pour les jeux", "Layar untuk game")) {
            VStack(alignment: .leading, spacing: 8) {
                Picker(L.t("Open games on", "Ouvrir les jeux sur", "Buka game di"), selection: $gameDisplay) {
                    Text(L.t("The main display", "L'écran principal", "Layar utama")).tag("")
                    ForEach(screens) { screen in
                        Text(screen.isBuiltin ? L.t("Built-in display", "Écran intégré", "Layar bawaan") : screen.name).tag(screen.key)
                    }
                }
                .frame(maxWidth: 380)
                Text(L.t("Windows games open on the macOS main display. When you launch Steam or a Windows app from MacPlay, the screen you pick becomes the main display (the menu bar and Dock move there too) until every game and launcher has closed, or you quit MacPlay. A launcher that is already running stays on its screen.",
                         "Les jeux Windows s'ouvrent sur l'écran principal de macOS. Quand tu lances Steam ou une app Windows depuis MacPlay, l'écran choisi devient l'écran principal (la barre des menus et le Dock y vont aussi) jusqu'à ce que tous les jeux et launchers soient fermés, ou que tu quittes MacPlay. Un launcher déjà ouvert reste sur son écran.",
                         "Game Windows terbuka di layar utama macOS. Saat kamu menjalankan Steam atau app Windows dari MacPlay, layar yang kamu pilih menjadi layar utama (bar menu dan Dock ikut pindah) sampai semua game dan launcher ditutup, atau kamu keluar dari MacPlay. Launcher yang sudah berjalan tetap di layarnya."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if rearranged {
                    HStack {
                        Label(L.t("Screens are rearranged for games right now.", "Les écrans sont réorganisés pour les jeux.", "Layar sedang diatur ulang untuk game."),
                              systemImage: "display.2")
                            .font(.callout)
                        Button(L.t("Restore now", "Rétablir", "Pulihkan sekarang")) {
                            GameDisplay.restore()
                            rearranged = GameDisplay.isRearranged
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }
}

struct HealthRow: View {
    let ok: Bool
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? .green : .orange)
        }
        .font(.callout)
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct LogPanel: View {
    @ObservedObject var runner: ActionRunner

    var body: some View {
        GroupBox {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(runner.log.enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .id(i)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 180)
                .onChange(of: runner.log.count) { count in
                    proxy.scrollTo(count - 1, anchor: .bottom)
                }
            }
        } label: {
            HStack {
                Text(L.t("Log", "Journal", "Log"))
                if runner.running { ProgressView().controlSize(.mini) }
            }
        }
    }
}
