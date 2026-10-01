import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Finder picker for a Windows .exe. `insidePackages` lets it browse into a
/// wrapper bundle, where an app's C: drive lives.
func pickExe(message: String, startIn directory: URL?, insidePackages: Bool = false) -> URL? {
    let panel = NSOpenPanel()
    panel.message = message
    panel.allowedContentTypes = [UTType(filenameExtension: "exe") ?? .data]
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.treatsFilePackagesAsDirectories = insidePackages
    panel.directoryURL = directory
    return panel.runModal() == .OK ? panel.url : nil
}

/// My Games or My Apps: the programs installed from a setup .exe in one category.
struct AppsView: View {
    let category: WindowsApp.Category

    @State private var apps: [WindowsApp] = []
    @State private var selected: WindowsApp?
    @State private var installer: URL?
    @State private var newName = ""
    @State private var installCategory: WindowsApp.Category = .app
    @StateObject private var runner = ActionRunner()

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(apps, selection: $selected) { app in
                    Text(app.name).lineLimit(1).tag(app)
                }
                .overlay {
                    if apps.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 32, weight: .thin))
                                .foregroundStyle(.tertiary)
                            Text(category == .game
                                 ? L.t("No games yet.\nInstall a game or a launcher from its setup .exe.",
                                       "Aucun jeu.\nInstalle un jeu ou un launcher depuis son .exe d'installation.",
                                       "Belum ada game.\nInstal game atau launcher dari file .exe instalasinya.")
                                 : L.t("No apps yet.\nInstall a Windows program from its setup .exe.",
                                       "Aucune app.\nInstalle un programme Windows depuis son .exe d'installation.",
                                       "Belum ada app.\nInstal program Windows dari file .exe instalasinya."))
                                .multilineTextAlignment(.center)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Divider()
                Button {
                    chooseInstaller()
                } label: {
                    Label(category == .game
                          ? L.t("Install a Windows game…", "Installer un jeu Windows…", "Instal game Windows…")
                          : L.t("Install a Windows program…", "Installer un programme Windows…", "Instal program Windows…"),
                          systemImage: "plus")
                }
                .disabled(runner.running)
                .padding(10)
            }
            .frame(width: 290)

            Divider()

            if let installer {
                installPanel(installer)
            } else if let app = selected {
                AppDetail(app: app, onRemoved: {
                    selected = nil
                    reloadApps()
                }, onRenamed: { renamed in
                    reloadApps()
                    selected = apps.first { $0.id == renamed.id }
                }, onCategoryChanged: {
                    // it now belongs to the other section
                    selected = nil
                    reloadApps()
                })
                .id(app.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.tertiary)
                    Text(category == .game
                         ? L.t("Install a Windows game or game launcher (TapTap, Battle.net…) from its .exe",
                               "Installe un jeu ou un launcher Windows (TapTap, Battle.net…) depuis son .exe",
                               "Instal game atau launcher game Windows (TapTap, Battle.net…) dari file .exe-nya")
                         : L.t("Install any other Windows program from its .exe",
                               "Installe n'importe quel autre programme Windows depuis son .exe",
                               "Instal program Windows lainnya dari file .exe-nya"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { reloadApps() }
        .onChange(of: runner.running) { isRunning in
            if !isRunning { reloadApps() }
        }
        .onChange(of: selected) { app in
            // picking an app leaves the install panel, except mid-install (its log matters)
            if app != nil && !runner.running { installer = nil }
        }
    }

    private func reloadApps() {
        apps = WindowsApps.list().filter { $0.category == category }
    }

    private func chooseInstaller() {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard let url = pickExe(message: category == .game
                                    ? L.t("Choose the game's or launcher's setup .exe",
                                          "Choisis le .exe d'installation du jeu ou du launcher",
                                          "Pilih file .exe instalasi game atau launcher")
                                    : L.t("Choose the program's setup .exe",
                                          "Choisis le .exe d'installation du programme",
                                          "Pilih file .exe instalasi program"),
                                startIn: downloads)
        else { return }
        selected = nil
        runner.log = []
        runner.lastExit = nil
        newName = WindowsApps.suggestedName(forInstaller: url)
        installCategory = category
        installer = url
    }

    private func installPanel(_ url: URL) -> some View {
        let finished = !runner.running && runner.lastExit != nil
        // validate only before starting: once running, the wrapper this install
        // creates would itself trip the "already exists" check
        let started = runner.running || finished
        let problem = started ? nil : WindowsApps.nameProblem(newName)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(installCategory == .game
                     ? L.t("Install a Windows game", "Installer un jeu Windows", "Instal game Windows")
                     : L.t("Install a Windows program", "Installer un programme Windows", "Instal program Windows"))
                    .font(.title.bold())

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        DetailRow(label: L.t("Installer", "Installeur", "File instalasi"), value: url.lastPathComponent)
                        HStack(alignment: .firstTextBaseline) {
                            Text(L.t("Name", "Nom", "Nama")).foregroundStyle(.secondary).frame(width: 160, alignment: .leading)
                            TextField("", text: $newName)
                                .textFieldStyle(.roundedBorder)
                                .disabled(started)
                        }
                        .font(.callout)
                        if let problem {
                            Text(problem).font(.caption).foregroundStyle(.orange)
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text(L.t("Category", "Catégorie", "Kategori")).foregroundStyle(.secondary).frame(width: 160, alignment: .leading)
                            CategoryPicker(selection: $installCategory)
                                .disabled(started)
                        }
                        .font(.callout)
                        Text(L.t("MacPlay builds a separate Wine wrapper for it in ~/Applications/Sikarugir (~1.4 GB on disk; ~250 MB download the first time), runs the installer, then finds the installed program. Games you install from inside it — from a launcher, say — live in that wrapper too.",
                                 "MacPlay crée un wrapper Wine séparé dans ~/Applications/Sikarugir (~1,4 Go sur le disque ; ~250 Mo téléchargés la première fois), lance l'installeur, puis trouve le programme installé. Les jeux que tu installes depuis celui-ci — depuis un launcher par exemple — vivent aussi dans ce wrapper.",
                                 "MacPlay membuat wrapper Wine tersendiri untuknya di ~/Applications/Sikarugir (~1,4 GB di disk; unduhan ~250 MB saat pertama kali), menjalankan installer, lalu mencari program yang terpasang. Game yang kamu instal dari dalamnya — misalnya dari launcher — juga tinggal di wrapper itu."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                HStack {
                    if finished {
                        if runner.lastExit == 0 {
                            Button(L.t("Show \(newName)", "Voir \(newName)", "Lihat \(newName)")) { showInstalled() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(L.t("Close", "Fermer", "Tutup")) { showInstalled() }
                        }
                    } else {
                        Button(L.t("Install", "Installer", "Instal")) {
                            let name = newName
                            let chosen = installCategory
                            runner.start(L.t("Installing \(name)", "Installation de \(name)", "Menginstal \(name)")) { emit, doneCb in
                                WindowsApps.install(installer: url, name: name, category: chosen, emit: emit, done: doneCb)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(problem != nil || runner.running)
                        Button(L.t("Cancel", "Annuler", "Batal")) { installer = nil }
                            .disabled(runner.running)
                    }
                }

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

    /// Leave the install panel for the new app (also after a failure: a half-built
    /// wrapper is listed so it can be fixed or uninstalled).
    private func showInstalled() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        reloadApps()
        installer = nil
        selected = apps.first { $0.name == name }
    }
}

struct AppDetail: View {
    let app: WindowsApp
    let onRemoved: () -> Void
    let onRenamed: (WindowsApp) -> Void
    let onCategoryChanged: () -> Void

    @StateObject private var runner = ActionRunner()
    @State private var program: String?
    @State private var flags = ""
    @State private var savedFlags = ""
    @State private var chosenBackend = "d3dmetal"
    @State private var activeBackend = "d3dmetal"
    @State private var running = false
    @State private var confirmUninstall = false
    @State private var problem: String?
    @State private var renaming = false
    @State private var newName = ""
    @State private var renameProblem: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(app.name).font(.title.bold())
                    Spacer()
                    if running {
                        Button {
                            runner.start(L.t("Stopping \(app.name)", "Arrêt de \(app.name)", "Menghentikan \(app.name)")) { emit, doneCb in
                                DispatchQueue.global(qos: .userInitiated).async {
                                    WindowsApps.stop(app)
                                    doneCb(0)
                                }
                            }
                        } label: {
                            Label(L.t("Stop", "Arrêter", "Hentikan"), systemImage: "stop.fill")
                        }
                        .controlSize(.large)
                        .disabled(runner.running)
                    } else {
                        Button {
                            WindowsApps.launch(app)
                        } label: {
                            Label(L.t("Launch", "Lancer", "Jalankan"), systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(program == nil || runner.running)
                    }
                }

                if running {
                    Label(L.t("Running. Games you start from it use the engine below; Stop closes them too.",
                              "En cours. Les jeux lancés depuis lui utilisent le moteur ci-dessous ; Arrêter les ferme aussi.",
                              "Sedang berjalan. Game yang kamu mulai dari sini memakai engine di bawah; Hentikan juga menutupnya."),
                          systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }

                GroupBox(L.t("Program", "Programme", "Program")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(program.map { "C:" + $0.replacingOccurrences(of: "/", with: "\\") }
                                 ?? L.t("No program set yet.", "Aucun programme défini.", "Belum ada program yang dipilih."))
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button(L.t("Change…", "Changer…", "Ganti…")) { changeProgram() }
                                .disabled(runner.running)
                        }
                        HStack {
                            TextField(L.t("Launch options (optional)", "Options de lancement (optionnel)", "Opsi peluncuran (opsional)"), text: $flags)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.callout, design: .monospaced))
                            Button(L.t("Save", "Enregistrer", "Simpan")) { saveFlags() }
                                .disabled(flags == savedFlags)
                        }
                        Text(L.t("Passed to the program when it starts, at the next launch.",
                                 "Passées au programme à son démarrage, au prochain lancement.",
                                 "Diteruskan ke program saat mulai, pada peluncuran berikutnya."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let problem {
                            Text(problem).font(.callout).foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                GroupBox(L.t("Graphics engine", "Moteur graphique", "Engine grafis")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L.t("Used by this program and every game it starts. If a game crashes or shows a black screen, try another one.",
                                 "Utilisé par ce programme et chaque jeu qu'il lance. Si un jeu plante ou reste noir, essaie-en un autre.",
                                 "Dipakai oleh program ini dan setiap game yang dijalankannya. Kalau game crash atau layarnya hitam, coba engine lain."))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $chosenBackend) {
                            ForEach(Engine.backendChoices(for: app.wrapperPath), id: \.id) { c in
                                Text(c.label).tag(c.id)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        HStack {
                            Button(L.t("Apply", "Appliquer", "Terapkan")) { applyBackend() }
                                .disabled(chosenBackend == activeBackend)
                            Text(running
                                 ? L.t("Stop and relaunch for it to take effect.", "Arrête puis relance pour l'appliquer.", "Hentikan lalu jalankan lagi agar berlaku.")
                                 : L.t("Currently active: \(activeBackend.uppercased())",
                                       "Actif actuellement : \(activeBackend.uppercased())",
                                       "Aktif sekarang: \(activeBackend.uppercased())"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(L.t("Listed in", "Classé dans", "Tercantum di")).foregroundStyle(.secondary)
                    // writes only when the player picks the other section
                    CategoryPicker(selection: Binding(get: { app.category }, set: { moveTo($0) }))
                        .frame(maxWidth: 260)
                }
                .font(.callout)

                HStack {
                    Button(L.t("Rename…", "Renommer…", "Ganti nama…")) {
                        newName = app.name
                        renaming = true
                    }
                    .disabled(running || runner.running)
                    .alert(L.t("Rename \(app.name)", "Renommer \(app.name)", "Ganti nama \(app.name)"), isPresented: $renaming) {
                        TextField(L.t("Name", "Nom", "Nama"), text: $newName)
                        Button(L.t("Rename", "Renommer", "Ganti nama")) { rename() }
                        Button(L.t("Cancel", "Annuler", "Batal"), role: .cancel) {}
                    } message: {
                        Text(L.t("Letters, numbers, spaces, - and _.", "Lettres, chiffres, espaces, - et _.", "Huruf, angka, spasi, - dan _."))
                    }

                    Button(role: .destructive) { confirmUninstall = true } label: {
                        Text(L.t("Uninstall \(app.name)…", "Désinstaller \(app.name)…", "Hapus instalasi \(app.name)…"))
                    }
                    .disabled(runner.running)
                    .confirmationDialog(
                        L.t("Uninstall \(app.name)? Its wrapper AND everything installed inside (games included) will be deleted.",
                            "Désinstaller \(app.name) ? Son wrapper ET tout ce qui y est installé (jeux compris) seront supprimés.",
                            "Hapus instalasi \(app.name)? Wrapper-nya DAN semua yang terinstal di dalamnya (termasuk game) akan dihapus."),
                        isPresented: $confirmUninstall, titleVisibility: .visible
                    ) {
                        Button(L.t("Uninstall everything", "Tout désinstaller", "Hapus semuanya"), role: .destructive) {
                            runner.start(L.t("Uninstalling \(app.name)", "Désinstallation de \(app.name)", "Menghapus instalasi \(app.name)")) { emit, doneCb in
                                WindowsApps.uninstall(app, emit: emit) { code in
                                    doneCb(code)
                                    if code == 0 { DispatchQueue.main.async { onRemoved() } }
                                }
                            }
                        }
                    }
                }
                if running {
                    Text(L.t("Stop it to rename it.", "Arrête-le pour le renommer.", "Hentikan dulu untuk mengganti namanya."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let renameProblem {
                    Text(renameProblem).font(.callout).foregroundStyle(.red)
                }

                if !runner.log.isEmpty {
                    LogPanel(runner: runner)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .task {
            reload()
            while !Task.isCancelled {
                let app = app
                running = await Task.detached { WindowsApps.isRunning(app) }.value
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private func moveTo(_ category: WindowsApp.Category) {
        guard category != app.category else { return }
        do {
            try WindowsApps.setCategory(category, for: app)
            onCategoryChanged()
        } catch {
            problem = error.localizedDescription
        }
    }

    private func rename() {
        guard newName.trimmingCharacters(in: .whitespaces) != app.name else { return }
        do {
            onRenamed(try WindowsApps.rename(app, to: newName))
        } catch {
            renameProblem = error.localizedDescription
        }
    }

    private func reload() {
        program = WindowsApps.programPath(of: app)
        flags = WindowsApps.programFlags(of: app)
        savedFlags = flags
        activeBackend = Engine.activeBackend(of: app.wrapperPath)
        chosenBackend = activeBackend
    }

    private func changeProgram() {
        guard let url = pickExe(message: L.t("Choose the program MacPlay should launch",
                                             "Choisis le programme que MacPlay doit lancer",
                                             "Pilih program yang harus dijalankan MacPlay"),
                                startIn: URL(fileURLWithPath: app.driveC),
                                insidePackages: true)
        else { return }
        do {
            try WindowsApps.setProgram(file: url, for: app)
            problem = nil
        } catch {
            problem = error.localizedDescription
        }
        reload()
    }

    private func saveFlags() {
        do {
            try WindowsApps.setProgramFlags(flags, for: app)
            problem = nil
        } catch {
            problem = error.localizedDescription
        }
        reload()
    }

    private func applyBackend() {
        do {
            _ = try Engine.applyBackend(chosenBackend, wrapper: app.wrapperPath)
            problem = nil
        } catch {
            problem = error.localizedDescription
        }
        reload()
    }
}

/// Game / App, labelled with the sections they lead to.
struct CategoryPicker: View {
    @Binding var selection: WindowsApp.Category

    var body: some View {
        Picker("", selection: $selection) {
            Text(L.t("My Games", "Mes jeux", "Game Saya")).tag(WindowsApp.Category.game)
            Text(L.t("My Apps", "Mes apps", "App Saya")).tag(WindowsApp.Category.app)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

extension WindowsApp.Category {
    var icon: String { self == .game ? "play.circle" : "macwindow" }
}
