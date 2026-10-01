import SwiftUI

private let statusOrder = ["gold", "silver", "bronze", "native", "blocked", "borked"]

struct GamesView: View {
    @State private var games: [GameEntry] = []
    @State private var selected: GameEntry?
    @State private var profile: HardwareProfile?
    @State private var search = ""
    @State private var generatedAt: String?
    @State private var checking = false
    @StateObject private var runner = ActionRunner()

    private var filtered: [GameEntry] {
        search.isEmpty ? games : games.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    private var sections: [(status: String, items: [GameEntry])] {
        statusOrder.compactMap { status in
            let items = filtered.filter { $0.status == status }
            return items.isEmpty ? nil : (status, items.sorted { $0.title < $1.title })
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                TextField(L.t("Search a game…", "Chercher un jeu…", "Cari game…"), text: $search)
                    .textFieldStyle(.roundedBorder)
                    .padding(10)
                List(selection: $selected) {
                    ForEach(sections, id: \.status) { section in
                        Section(statusLabel(section.status)) {
                            ForEach(section.items) { game in
                                HStack {
                                    Circle()
                                        .fill(statusColor(game.status))
                                        .frame(width: 8, height: 8)
                                    Text(game.title).lineLimit(1)
                                }
                                .tag(game)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Theme.panel)
                Divider()
                listFooter
            }
            .frame(width: 300)

            Divider()

            if let game = selected {
                GameDetail(game: game, profile: profile, runner: runner)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.tertiary)
                    Text(L.t("Pick a game to see its recommended setup",
                             "Choisis un jeu pour voir sa configuration recommandée",
                             "Pilih game untuk melihat pengaturan yang disarankan"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            reload()
            profile = await Task.detached { Engine.detect() }.value
            await checkForUpdate(force: false)
        }
    }

    private var listFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(generatedAt.map { L.t("Updated \($0.prefix(10))", "Mise à jour du \($0.prefix(10))", "Diperbarui \($0.prefix(10))") }
                     ?? L.t("Built-in list", "Liste intégrée", "Daftar bawaan"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if checking { ProgressView().controlSize(.mini) }
                Button(L.t("Check now", "Vérifier", "Periksa sekarang")) { Task { await checkForUpdate(force: true) } }
                    .controlSize(.small)
                    .disabled(checking)
            }
            Text(L.t("\(games.count) games · MacPlay, AppleGamingWiki, AreWeAntiCheatYet",
                     "\(games.count) jeux · MacPlay, AppleGamingWiki, AreWeAntiCheatYet",
                     "\(games.count) game · MacPlay, AppleGamingWiki, AreWeAntiCheatYet"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
    }

    private func reload() {
        let file = CompatDB.load()
        games = file?.games ?? []
        generatedAt = file?.generated_at
    }

    private func checkForUpdate(force: Bool) async {
        checking = true
        if await CompatDB.refresh(force: force) { reload() }
        checking = false
    }
}

func statusColor(_ status: String) -> Color {
    switch status {
    case "gold": return .yellow
    case "silver": return .gray
    case "bronze": return .orange
    case "native": return .green
    default: return .red
    }
}

func statusLabel(_ status: String) -> String {
    switch status {
    case "gold": return L.t("Runs great", "Excellent", "Jalan mulus")
    case "silver": return L.t("Playable", "Jouable", "Bisa dimainkan")
    case "bronze": return L.t("Rough", "Limite", "Kurang mulus")
    case "native": return L.t("Native on Mac", "Natif Mac", "Native di Mac")
    case "blocked": return L.t("Blocked (anticheat)", "Bloqué (anticheat)", "Diblokir (anti-cheat)")
    default: return L.t("Not working", "Ne marche pas", "Tidak jalan")
    }
}

struct GameDetail: View {
    let game: GameEntry
    let profile: HardwareProfile?
    @ObservedObject var runner: ActionRunner

    private var tierSettings: TierSettings? {
        guard let settings = game.settings, !settings.isEmpty else { return nil }
        let tier = profile?.tier ?? "default"
        let order = ["ultra", "max", "pro", "base"]
        if let s = settings[tier] { return s }
        if let idx = order.firstIndex(of: tier) {
            for t in order[idx...] where settings[t] != nil { return settings[t] }
        }
        return settings["default"]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let appid = game.steam_appid {
                    ArtImage(appid: appid, kind: .banner, title: "")
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(game.title).font(Theme.title(28))
                    Spacer()
                    Text(statusLabel(game.status))
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor(game.status).opacity(0.2), in: Capsule())
                }

                if game.status == "blocked" {
                    Label(game.localizedNotes
                            ?? L.t("Incompatible anticheat: this game cannot run through Wine.",
                                   "Anticheat incompatible : ce jeu ne peut pas tourner via Wine.",
                                   "Anti-cheat tidak kompatibel: game ini tidak bisa jalan lewat Wine."),
                          systemImage: "xmark.shield")
                        .foregroundStyle(.red)
                } else if game.status == "native" {
                    Label(L.t("A native Mac version exists — play it on your regular macOS Steam.",
                              "Version Mac native disponible — joue-la sur ton Steam macOS normal.",
                              "Ada versi native Mac — mainkan lewat Steam macOS biasa."),
                          systemImage: "checkmark.seal")
                        .foregroundStyle(.green)
                    if let notes = game.localizedNotes {
                        Text(notes).font(.callout).foregroundStyle(.secondary)
                    }
                } else if game.status == "borked" {
                    Label(game.localizedNotes ?? L.t("Does not work through the wrapper.",
                                                     "Ne fonctionne pas via le wrapper.",
                                                     "Tidak jalan lewat wrapper."),
                          systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                } else {
                    if let est = Perf.estimate(profile: profile, game: game) {
                        Label {
                            Text(L.t("On your \(profile?.chip ?? "Mac") (\(profile?.gpuCores ?? 0) GPU cores): ~\(est.fpsRange) fps expected — \(est.hint). Estimate, not a promise.",
                                     "Sur ta \(profile?.chip ?? "machine") (\(profile?.gpuCores ?? 0) cœurs GPU) : ~\(est.fpsRange) fps attendus — \(est.hint). Estimation, pas une promesse.",
                                     "Di \(profile?.chip ?? "Mac") kamu (\(profile?.gpuCores ?? 0) core GPU): perkiraan ~\(est.fpsRange) fps — \(est.hint). Perkiraan, bukan janji."))
                        } icon: {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }

                    GroupBox(L.t("Setup for your Mac", "Configuration pour ta machine", "Pengaturan untuk Mac kamu")
                             + (profile.map { " (\($0.chip))" } ?? "")) {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: L.t("Graphics backend", "Backend graphique", "Backend grafis"),
                                      value: game.backend.isEmpty
                                        ? L.t("No recommendation yet (D3DMetal is the default)",
                                              "Pas encore de recommandation (D3DMetal par défaut)",
                                              "Belum ada rekomendasi (default: D3DMetal)")
                                        : game.backend.uppercased())
                            if let dx = game.dx, !dx.isEmpty {
                                DetailRow(label: "API", value: dx.uppercased())
                            }
                            if let s = tierSettings {
                                DetailRow(label: L.t("Preset", "Preset", "Preset"), value: s.preset)
                                DetailRow(label: "Upscaling", value: s.upscaling)
                                if let extra = s.extra, !extra.isEmpty {
                                    DetailRow(label: L.t("Also set", "À régler", "Atur juga"), value: extra)
                                }
                            }
                            if let lo = game.launch_options, !lo.isEmpty {
                                DetailRow(label: L.t("Launch options", "Options de lancement", "Opsi peluncuran"), value: lo, mono: true)
                            }
                            if let ram = game.ram_min_gb, let p = profile, p.ramGB <= ram {
                                Label(L.t("Your Mac is at the RAM minimum (\(ram) GB): close browsers and heavy apps before playing.",
                                          "Ta machine est au minimum RAM (\(ram) Go) : ferme navigateurs et grosses apps avant de jouer.",
                                          "RAM Mac kamu pas di batas minimum (\(ram) GB): tutup browser dan app berat sebelum main."),
                                      systemImage: "memorychip")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }

                    if let appid = game.steam_appid, Engine.wrapperInstalled {
                        HStack {
                            Button {
                                let title = game.title
                                runner.start(L.t("Install \(title)", "Installation de \(title)", "Instal \(title)")) { emit, doneCb in
                                    Engine.installGame(appid: String(appid), gameTitle: title, emit: emit, done: doneCb)
                                }
                            } label: {
                                Label(L.t("Install via Steam", "Installer via Steam", "Instal lewat Steam"), systemImage: "square.and.arrow.down")
                            }
                            .disabled(runner.running)
                            Text(L.t("Opens the Steam install window (game must be owned or free).",
                                     "Ouvre la fenêtre d'installation Steam (jeu possédé ou gratuit).",
                                     "Membuka jendela instalasi Steam (game harus sudah dimiliki atau gratis)."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !game.backend.isEmpty {
                    HStack {
                        Button(L.t("Apply and restart Steam", "Appliquer et relancer Steam", "Terapkan dan mulai ulang Steam")) {
                            let backend = game.backend
                            runner.start(L.t("Setting \(backend.uppercased()) for \(game.title)",
                                             "Configuration \(backend.uppercased()) pour \(game.title)",
                                             "Memasang \(backend.uppercased()) untuk \(game.title)")) { emit, doneCb in
                                do {
                                    let applied = try Engine.applyBackend(backend)
                                    emit(L.t("Backend set to \(applied).", "Backend réglé sur \(applied).", "Backend diatur ke \(applied)."))
                                    Engine.restart(emit: emit, done: doneCb)
                                } catch {
                                    emit(error.localizedDescription)
                                    doneCb(1)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(runner.running)
                        Text(L.t("Sets the wrapper backend, then restarts the Wine session.",
                                 "Règle le backend du wrapper puis redémarre la session Wine.",
                                 "Mengatur backend wrapper, lalu memulai ulang sesi Wine."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    }

                    if let fixes = game.fixes, !fixes.isEmpty {
                        GroupBox(L.t("Known issues", "Problèmes connus", "Masalah yang diketahui")) {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(fixes, id: \.symptom) { f in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(f.localizedSymptom).font(.callout.weight(.medium))
                                        Text(f.localizedFix).font(.callout).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(4)
                        }
                    }

                    if let notes = game.localizedNotes {
                        Text(notes).font(.callout).foregroundStyle(.secondary)
                    }
                }

                CommunityReports(game: game)

                if !runner.log.isEmpty {
                    LogPanel(runner: runner)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var mono = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary).frame(width: 160, alignment: .leading)
            Text(value)
                .font(mono ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
        .font(.callout)
    }
}

/// What the imported sources say about a game, with links back to them.
struct CommunityReports: View {
    let game: GameEntry

    var body: some View {
        if game.wiki_rating != nil || game.anticheat_status != nil || !game.isCurated {
            GroupBox(L.t("Community reports", "Retours de la communauté", "Laporan komunitas")) {
                VStack(alignment: .leading, spacing: 10) {
                    if let rating = game.wiki_rating {
                        reportRow(source: "AppleGamingWiki",
                                  summary: wikiRatingLabel(rating) + " — " + methodLabel(game.wiki_method),
                                  detail: game.wiki_reported.map { L.t("Latest report: \($0)", "Dernier retour : \($0)", "Laporan terbaru: \($0)") }
                                    ?? L.t("Undated report", "Retour non daté", "Laporan tanpa tanggal"),
                                  link: game.wiki_url)
                    }
                    if let status = game.anticheat_status {
                        reportRow(source: "AreWeAntiCheatYet",
                                  summary: ([status] + (game.anticheats ?? [])).joined(separator: " — "),
                                  detail: L.t("Anti-cheat status under Wine/Proton on Linux",
                                              "Statut de l'anti-triche sous Wine/Proton sur Linux",
                                              "Status anti-cheat di Wine/Proton pada Linux"),
                                  link: game.anticheat_url)
                    }
                    if !game.isCurated {
                        Text(game.source == "areweanticheatyet"
                             ? L.t("Imported from AreWeAntiCheatYet (MIT). MacPlay has not tested this game.",
                                   "Importé d'AreWeAntiCheatYet (MIT). MacPlay n'a pas testé ce jeu.",
                                   "Diimpor dari AreWeAntiCheatYet (MIT). MacPlay belum menguji game ini.")
                             : L.t("Imported from AppleGamingWiki (CC BY-NC-SA 3.0). MacPlay has not tested this game.",
                                   "Importé d'AppleGamingWiki (CC BY-NC-SA 3.0). MacPlay n'a pas testé ce jeu.",
                                   "Diimpor dari AppleGamingWiki (CC BY-NC-SA 3.0). MacPlay belum menguji game ini."))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }
        }
    }

    private func reportRow(source: String, summary: String, detail: String, link: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(source).foregroundStyle(.secondary).frame(width: 160, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let link, let url = URL(string: link) {
                Link(L.t("Open", "Ouvrir", "Buka"), destination: url)
            }
        }
        .font(.callout)
    }

    private func wikiRatingLabel(_ rating: String) -> String {
        switch rating {
        case "perfect": return L.t("Perfect", "Parfait", "Sempurna")
        case "playable": return L.t("Playable", "Jouable", "Bisa dimainkan")
        case "runs": return L.t("Runs, with issues", "Se lance, avec des soucis", "Jalan, dengan masalah")
        case "menu": return L.t("Menu only", "Menu seulement", "Hanya sampai menu")
        default: return L.t("Unplayable", "Injouable", "Tidak bisa dimainkan")
        }
    }

    private func methodLabel(_ method: String?) -> String {
        method == "wine" ? "Wine" : "CrossOver"
    }
}
