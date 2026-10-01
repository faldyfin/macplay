import SwiftUI

/// Where a Home card leads.
enum HomeRoute: Hashable {
    case steam(InstalledGame)
    case program(WindowsApp)
    case compatible(GameEntry)
}

/// One thing Home can show: an installed Steam game, a program, or a compatible game.
struct HomeItem: Identifiable, Hashable {
    let route: HomeRoute
    let title: String
    let appid: Int?
    var id: String {
        switch route {
        case .steam(let g): return "steam:" + g.appid
        case .program(let a): return "app:" + a.name
        case .compatible(let e): return "compat:" + e.id
        }
    }
    /// Key under which PlayTime records this item.
    var playKey: String? {
        switch route {
        case .steam(let g): return PlayTime.steamKey(g.appid)
        case .program(let a): return PlayTime.appKey(a.name)
        case .compatible: return nil
        }
    }
}

struct HomeView: View {
    @ObservedObject private var playTime = PlayTime.shared
    @ObservedObject private var chosen = ChosenArt.shared
    @StateObject private var session = GameSession()
    @StateObject private var runner = ActionRunner()

    @State private var path = NavigationPath()
    @State private var steamGames: [InstalledGame] = []
    @State private var programs: [WindowsApp] = []
    @State private var compatible: [GameEntry] = []
    @State private var profile: HardwareProfile?
    @State private var steamRunning = false
    @State private var search = ""
    @State private var coverTarget: CoverTarget?

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            header
                            if search.trimmingCharacters(in: .whitespaces).isEmpty {
                                if let featured { hero(featured) }
                                row(L.t("Your games", "Tes jeux", "Game kamu"), items: yourGames,
                                    empty: L.t("Install a game from Steam or My Games and it shows up here.",
                                               "Installe un jeu depuis Steam ou Mes jeux et il apparaîtra ici.",
                                               "Instal game dari Steam atau Game Saya, nanti muncul di sini."))
                                row(L.t("Runs great on your Mac", "Tourne très bien sur ton Mac", "Jalan mulus di Mac kamu"),
                                    items: runsGreat, empty: nil)
                                if !wide(geo) {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14, alignment: .top)],
                                              alignment: .leading, spacing: 14) {
                                        sideCards
                                    }
                                }
                            } else {
                                searchResults
                            }
                        }
                        .padding(28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if wide(geo) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) { sideCards }
                                .padding(18)
                        }
                        .frame(width: 280)
                        .background(Theme.panel)
                    }
                }
            }
            .background(Theme.background)
            .navigationDestination(for: HomeRoute.self) { route in destination(route) }
        }
        .task { await reload() }
        .sheet(item: $coverTarget) { CoverPicker(target: $0) }
    }

    // MARK: data

    private func reload() async {
        steamGames = SteamLibrary.installedGames()
        programs = WindowsApps.list()
        compatible = Engine.loadGames()
        steamRunning = await Task.detached { Engine.steamUIAlive }.value
        if profile == nil { profile = await Task.detached { Engine.detect() }.value }
    }

    private func item(_ game: InstalledGame) -> HomeItem {
        HomeItem(route: .steam(game), title: game.name, appid: Int(game.appid))
    }

    private func item(_ app: WindowsApp) -> HomeItem {
        HomeItem(route: .program(app), title: app.name, appid: nil)
    }

    private func item(_ entry: GameEntry) -> HomeItem {
        HomeItem(route: .compatible(entry), title: entry.title, appid: entry.steam_appid)
    }

    private var yourGames: [HomeItem] {
        steamGames.map(item) + programs.filter { $0.category == .game }.map(item)
    }

    /// Hand-tuned "runs great" games only: the cards show no source, which imported ratings need.
    private var runsGreat: [HomeItem] {
        let installed = Set(steamGames.map(\.appid))
        let gold = compatible.filter { $0.isCurated && $0.status == "gold" && $0.steam_appid != nil
            && !installed.contains(String($0.steam_appid!)) }
        return gold.prefix(16).map(item)
    }

    /// Most-played installed title, else the most recently added, else a hand-tuned favourite.
    private var featured: HomeItem? {
        let installedItems = yourGames
        if let best = installedItems
            .compactMap({ item in item.playKey.flatMap { playTime.entries[$0] }.map { (item, $0.seconds) } })
            .max(by: { $0.1 < $1.1 }) {
            return best.0
        }
        if let latest = installedItems.max(by: { (addedDate($0) ?? .distantPast) < (addedDate($1) ?? .distantPast) }) {
            return latest
        }
        return runsGreat.first
    }

    private func addedDate(_ item: HomeItem) -> Date? {
        let fm = FileManager.default
        switch item.route {
        case .steam(let g):
            let manifest = SteamLibrary.steamappsPath + "/appmanifest_\(g.appid).acf"
            return (try? fm.attributesOfItem(atPath: manifest))?[.modificationDate] as? Date
        case .program(let a):
            // the .app folder keeps the Sikarugir template's date; Contents is made per wrapper
            return (try? fm.attributesOfItem(atPath: a.wrapperPath + "/Contents"))?[.creationDate] as? Date
        case .compatible:
            return nil
        }
    }

    private func title(forPlayKey key: String) -> String {
        if key.hasPrefix("steam:") {
            let appid = String(key.dropFirst(6))
            return steamGames.first { $0.appid == appid }?.name
                ?? compatible.first { $0.steam_appid.map(String.init) == appid }?.title
                ?? "Steam \(appid)"
        }
        return String(key.dropFirst(4))
    }

    // MARK: header and search

    private var greeting: String {
        let first = NSFullUserName().split(separator: " ").first.map(String.init) ?? NSUserName()
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return L.t("Good morning, \(first)", "Bonjour, \(first)", "Selamat pagi, \(first)") }
        if hour < 18 { return L.t("Good afternoon, \(first)", "Bon après-midi, \(first)", "Selamat siang, \(first)") }
        return L.t("Good evening, \(first)", "Bonsoir, \(first)", "Selamat malam, \(first)")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.text)
                Text(L.t("What are you playing today?", "Tu joues à quoi aujourd'hui ?", "Mau main apa hari ini?"))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField(L.t("Search games", "Chercher un jeu", "Cari game"), text: $search)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.text)
                    .onExitCommand { search = "" }
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(width: 280)
            .background(Theme.panel, in: Capsule())
        }
    }

    private var searchResults: some View {
        let query = search.trimmingCharacters(in: .whitespaces)
        let matches = searchMatches(query)
        return VStack(alignment: .leading, spacing: 10) {
            Text(L.t("Results", "Résultats", "Hasil"))
                .font(Theme.title(20))
                .foregroundStyle(Theme.text)
            if matches.isEmpty {
                Text(L.t("No game matches “\(query)”.", "Aucun jeu ne correspond à « \(query) ».",
                         "Tidak ada game yang cocok dengan “\(query)”."))
                    .foregroundStyle(Theme.muted)
            }
            ForEach(matches) { match in
                NavigationLink(value: match.route) {
                    HStack(spacing: 14) {
                        ArtImage(appid: match.appid, kind: .banner, title: match.title, key: match.playKey)
                            .frame(width: 128, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(match.title).font(.headline).foregroundStyle(Theme.text)
                            Text(subtitle(for: match)).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func searchMatches(_ query: String) -> [HomeItem] {
        let installedIDs = Set(steamGames.map(\.appid))
        var matches: [HomeItem] = steamGames.filter { $0.name.localizedCaseInsensitiveContains(query) }.map(item)
        matches += programs.filter { $0.name.localizedCaseInsensitiveContains(query) }.map(item)
        let others = compatible.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query)
                && !installedIDs.contains(entry.steam_appid.map(String.init) ?? "")
        }
        matches += others.prefix(40).map(item)
        return matches
    }

    private func subtitle(for item: HomeItem) -> String {
        switch item.route {
        case .steam: return L.t("Installed in Steam", "Installé dans Steam", "Terinstal di Steam")
        case .program(let a): return a.category == .game ? L.t("My Games", "Mes jeux", "Game Saya")
                                                         : L.t("My Apps", "Mes apps", "App Saya")
        case .compatible(let e): return statusLabel(e.status)
        }
    }

    // MARK: hero and rows

    private func hero(_ featured: HomeItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            ArtImage(appid: featured.appid, kind: .banner, title: "", key: featured.playKey)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
            // scrim: keeps the title legible on any artwork
            LinearGradient(colors: [.clear, Theme.background.opacity(0.95)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 10) {
                // backed so they stay readable on bright artwork
                Chip(text: subtitle(for: featured))
                    .background(Theme.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(featured.title)
                    .font(Theme.title(40))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.5), radius: 8)
                if let key = featured.playKey, let seconds = playTime.entries[key]?.seconds {
                    Text(L.t("Played \(playTimeText(seconds))", "Joué \(playTimeText(seconds))",
                             "Dimainkan \(playTimeText(seconds))"))
                        .foregroundStyle(Theme.text.opacity(0.8))
                }
                HStack(spacing: 10) {
                    primaryAction(featured)
                    if case .compatible = featured.route {} else {
                        NavigationLink(value: featured.route) {
                            Text(L.t("Details", "Détails", "Detail"))
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(.white.opacity(0.14), in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let line = session.statusLine, session.phase != .idle {
                    Text(line).font(.callout).foregroundStyle(Theme.text.opacity(0.85))
                }
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            chooseArtButton(featured, .banner).padding(20)
        }
        .contextMenu { artMenu(featured, .banner) }
    }

    /// "Change cover…" / "Change banner…" and the reset, for installed games and programs.
    @ViewBuilder
    private func artMenu(_ item: HomeItem, _ kind: GameArt.Kind) -> some View {
        if let key = item.playKey {
            Button(kind == .cover ? L.t("Change cover…", "Changer la jaquette…", "Ganti sampul…")
                                  : L.t("Change banner…", "Changer la bannière…", "Ganti banner…")) {
                coverTarget = CoverTarget(key: key, title: item.title, kind: kind)
            }
            if chosen.has(key, kind) {
                Button(L.t("Use default artwork", "Illustration par défaut", "Pakai gambar bawaan")) {
                    chosen.remove(key, kind)
                }
            }
        }
    }

    /// On a program's artwork until the player picks one; Steam games have Steam's.
    @ViewBuilder
    private func chooseArtButton(_ item: HomeItem, _ kind: GameArt.Kind) -> some View {
        if case .program = item.route, let key = item.playKey, !chosen.has(key, kind) {
            Button {
                coverTarget = CoverTarget(key: key, title: item.title, kind: kind)
            } label: {
                Label(kind == .cover ? L.t("Choose a cover", "Choisir une jaquette", "Pilih sampul")
                                     : L.t("Choose a banner", "Choisir une bannière", "Pilih banner"),
                      systemImage: "photo")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func actionLabel(_ item: HomeItem) -> String {
        switch item.route {
        case .steam: return L.t("Play", "Jouer", "Main")
        case .program: return L.t("Launch", "Lancer", "Jalankan")
        case .compatible: return L.t("See how it runs", "Voir comment il tourne", "Lihat cara jalannya")
        }
    }

    private func primaryAction(_ item: HomeItem) -> some View {
        Button {
            switch item.route {
            case .steam(let game): session.play(game)
            case .program(let app): WindowsApps.launch(app)
            case .compatible: path.append(item.route)
            }
        } label: {
            Label(actionLabel(item), systemImage: "play.fill")
                .font(.headline)
                .padding(.horizontal, 22).padding(.vertical, 10)
                .background(Theme.accent, in: Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(session.phase == .launching || session.phase == .waitingForGame || session.phase == .running)
    }

    private func row(_ title: String, items: [HomeItem], empty: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(Theme.title(20)).foregroundStyle(Theme.text)
            if items.isEmpty, let empty {
                Text(empty).foregroundStyle(Theme.muted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { card($0) }
                }
            }
        }
    }

    private func card(_ item: HomeItem) -> some View {
        NavigationLink(value: item.route) {
            VStack(alignment: .leading, spacing: 8) {
                ArtImage(appid: item.appid, kind: .cover, title: item.title, key: item.playKey)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if let key = item.playKey, playTime.running.contains(key) {
                            Chip(text: L.t("Running", "En cours", "Berjalan"), color: .green)
                                .padding(8)
                        }
                    }
                Text(item.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        // over the link rather than inside it, so the button gets its own click
        .overlay(alignment: .top) {
            chooseArtButton(item, .cover).frame(width: 150, height: 210, alignment: .bottom)
        }
        .contextMenu { artMenu(item, .cover) }
    }

    @ViewBuilder
    private func destination(_ route: HomeRoute) -> some View {
        switch route {
        case .steam(let game):
            InstalledDetail(game: game,
                            known: compatible.first { $0.steam_appid.map(String.init) == game.appid },
                            stats: nil, profile: profile) { _ in }
        case .program(let app):
            AppDetail(app: app, onRemoved: {
                path = NavigationPath()
                Task { await reload() }
            }, onRenamed: { _ in
                path = NavigationPath()
                Task { await reload() }
            }, onCategoryChanged: {
                Task { await reload() }
            })
        case .compatible(let entry):
            GameDetail(game: entry, profile: profile, runner: runner)
        }
    }

    // MARK: side cards

    /// Room for the cards beside the rows; narrower windows show them under the rows instead.
    private func wide(_ geo: GeometryProxy) -> Bool { geo.size.width > 960 }

    @ViewBuilder
    private var sideCards: some View {
        GroupBox(L.t("Running now", "En cours", "Sedang berjalan")) {
            VStack(alignment: .leading, spacing: 6) {
                if steamRunning {
                    Label("Steam", systemImage: "cloud.fill").foregroundStyle(Theme.text)
                }
                ForEach(playTime.running, id: \.self) { key in
                    Label(title(forPlayKey: key), systemImage: "play.fill").foregroundStyle(Theme.text)
                }
                if !steamRunning && playTime.running.isEmpty {
                    Text(L.t("Nothing running", "Rien en cours", "Tidak ada yang berjalan"))
                        .foregroundStyle(Theme.muted)
                }
            }
            .font(.callout)
        }

        GroupBox(L.t("Your Mac", "Ton Mac", "Mac kamu")) {
            VStack(alignment: .leading, spacing: 6) {
                if let p = profile {
                    Text(p.chip).font(Theme.title(18)).foregroundStyle(Theme.text)
                    Text(L.t("\(p.ramGB) GB memory", "\(p.ramGB) Go de mémoire", "Memori \(p.ramGB) GB"))
                    if let cores = p.gpuCores {
                        Text(L.t("\(cores)-core GPU", "GPU \(cores) cœurs", "GPU \(cores) core"))
                    }
                } else {
                    ProgressView().controlSize(.small)
                }
            }
            .font(.callout)
            .foregroundStyle(Theme.muted)
        }

        GroupBox(L.t("Play time", "Temps de jeu", "Waktu bermain")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(playTimeText(playTime.totalSeconds))
                    .font(Theme.title(28))
                    .foregroundStyle(Theme.accent)
                ForEach(playTime.mostPlayed.prefix(3), id: \.key) { top in
                    HStack {
                        Text(title(forPlayKey: top.key)).lineLimit(1).foregroundStyle(Theme.text)
                        Spacer()
                        Text(playTimeText(top.entry.seconds)).foregroundStyle(Theme.muted)
                    }
                    .font(.callout)
                }
                Text(L.t("Counted while MacPlay is open.", "Compté quand MacPlay est ouvert.",
                         "Dihitung selama MacPlay terbuka."))
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }

        GroupBox(L.t("Recently added", "Ajoutés récemment", "Baru ditambahkan")) {
            VStack(alignment: .leading, spacing: 6) {
                let recent = (steamGames.map(item) + programs.map(item))
                    .compactMap { i in addedDate(i).map { (i, $0) } }
                    .sorted { $0.1 > $1.1 }
                    .prefix(3)
                if recent.isEmpty {
                    Text(L.t("Nothing installed yet", "Rien d'installé", "Belum ada yang terinstal"))
                        .foregroundStyle(Theme.muted)
                }
                ForEach(Array(recent), id: \.0.id) { entry in
                    HStack {
                        Text(entry.0.title).lineLimit(1).foregroundStyle(Theme.text)
                        Spacer()
                        Text(entry.1.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .font(.callout)
        }
    }
}
