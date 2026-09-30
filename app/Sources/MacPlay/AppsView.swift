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

struct AppsView: View {
    @State private var apps: [WindowsApp] = []
    @State private var selected: WindowsApp?
    @State private var installer: URL?
    @State private var newName = ""
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
                            Image(systemName: "macwindow")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundStyle(.tertiary)
                            Text(L.t("No Windows programs yet.\nInstall one from its setup .exe.",
                                     "Aucun programme Windows.\nInstalles-en un depuis son .exe d'installation."))
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
                    Label(L.t("Install a Windows program…", "Installer un programme Windows…"),
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
                AppDetail(app: app) {
                    selected = nil
                    apps = WindowsApps.list()
                }
                .id(app.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.tertiary)
                    Text(L.t("Install any Windows program — a game or another launcher — from its .exe",
                             "Installe n'importe quel programme Windows — un jeu ou un autre launcher — depuis son .exe"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { apps = WindowsApps.list() }
        .onChange(of: runner.running) { isRunning in
            if !isRunning { apps = WindowsApps.list() }
        }
        .onChange(of: selected) { app in
            // picking an app leaves the install panel, except mid-install (its log matters)
            if app != nil && !runner.running { installer = nil }
        }
    }

    private func chooseInstaller() {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard let url = pickExe(message: L.t("Choose the program's setup .exe",
                                             "Choisis le .exe d'installation du programme"),
                                startIn: downloads)
        else { return }
        selected = nil
        runner.log = []
        runner.lastExit = nil
        newName = WindowsApps.suggestedName(forInstaller: url)
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
                Text(L.t("Install a Windows program", "Installer un programme Windows"))
                    .font(.title.bold())

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        DetailRow(label: L.t("Installer", "Installeur"), value: url.lastPathComponent)
                        HStack(alignment: .firstTextBaseline) {
                            Text(L.t("Name", "Nom")).foregroundStyle(.secondary).frame(width: 160, alignment: .leading)
                            TextField("", text: $newName)
                                .textFieldStyle(.roundedBorder)
                                .disabled(started)
                        }
                        .font(.callout)
                        if let problem {
                            Text(problem).font(.caption).foregroundStyle(.orange)
                        }
                        Text(L.t("MacPlay builds a separate Wine wrapper for it in ~/Applications/Sikarugir (~1.4 GB on disk; ~250 MB download the first time), runs the installer, then finds the installed program. Games you install from inside it — from a launcher, say — live in that wrapper too.",
                                 "MacPlay crée un wrapper Wine séparé dans ~/Applications/Sikarugir (~1,4 Go sur le disque ; ~250 Mo téléchargés la première fois), lance l'installeur, puis trouve le programme installé. Les jeux que tu installes depuis celui-ci — depuis un launcher par exemple — vivent aussi dans ce wrapper."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                HStack {
                    if finished {
                        if runner.lastExit == 0 {
                            Button(L.t("Show \(newName)", "Voir \(newName)")) { showInstalled() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(L.t("Close", "Fermer")) { showInstalled() }
                        }
                    } else {
                        Button(L.t("Install", "Installer")) {
                            let name = newName
                            runner.start(L.t("Installing \(name)", "Installation de \(name)")) { emit, doneCb in
                                WindowsApps.install(installer: url, name: name, emit: emit, done: doneCb)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(problem != nil || runner.running)
                        Button(L.t("Cancel", "Annuler")) { installer = nil }
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
        apps = WindowsApps.list()
        installer = nil
        selected = apps.first { $0.name == name }
    }
}

struct AppDetail: View {
    let app: WindowsApp
    let onRemoved: () -> Void

    @StateObject private var runner = ActionRunner()
    @State private var program: String?
    @State private var flags = ""
    @State private var savedFlags = ""
    @State private var chosenBackend = "d3dmetal"
    @State private var activeBackend = "d3dmetal"
    @State private var running = false
    @State private var confirmUninstall = false
    @State private var problem: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(app.name).font(.title.bold())
                    Spacer()
                    if running {
                        Button {
                            runner.start(L.t("Stopping \(app.name)", "Arrêt de \(app.name)")) { emit, doneCb in
                                DispatchQueue.global(qos: .userInitiated).async {
                                    WindowsApps.stop(app)
                                    doneCb(0)
                                }
                            }
                        } label: {
                            Label(L.t("Stop", "Arrêter"), systemImage: "stop.fill")
                        }
                        .controlSize(.large)
                        .disabled(runner.running)
                    } else {
                        Button {
                            WindowsApps.launch(app)
                        } label: {
                            Label(L.t("Launch", "Lancer"), systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(program == nil || runner.running)
                    }
                }

                if running {
                    Label(L.t("Running. Games you start from it use the engine below; Stop closes them too.",
                              "En cours. Les jeux lancés depuis lui utilisent le moteur ci-dessous ; Arrêter les ferme aussi."),
                          systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }

                GroupBox(L.t("Program", "Programme")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(program.map { "C:" + $0.replacingOccurrences(of: "/", with: "\\") }
                                 ?? L.t("No program set yet.", "Aucun programme défini."))
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button(L.t("Change…", "Changer…")) { changeProgram() }
                                .disabled(runner.running)
                        }
                        HStack {
                            TextField(L.t("Launch options (optional)", "Options de lancement (optionnel)"), text: $flags)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.callout, design: .monospaced))
                            Button(L.t("Save", "Enregistrer")) { saveFlags() }
                                .disabled(flags == savedFlags)
                        }
                        Text(L.t("Passed to the program when it starts, at the next launch.",
                                 "Passées au programme à son démarrage, au prochain lancement."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let problem {
                            Text(problem).font(.callout).foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                GroupBox(L.t("Graphics engine", "Moteur graphique")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L.t("Used by this program and every game it starts. If a game crashes or shows a black screen, try another one.",
                                 "Utilisé par ce programme et chaque jeu qu'il lance. Si un jeu plante ou reste noir, essaie-en un autre."))
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
                            Button(L.t("Apply", "Appliquer")) { applyBackend() }
                                .disabled(chosenBackend == activeBackend)
                            Text(running
                                 ? L.t("Stop and relaunch for it to take effect.", "Arrête puis relance pour l'appliquer.")
                                 : L.t("Currently active: \(activeBackend.uppercased())",
                                       "Actif actuellement : \(activeBackend.uppercased())"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }

                Button(role: .destructive) { confirmUninstall = true } label: {
                    Text(L.t("Uninstall \(app.name)…", "Désinstaller \(app.name)…"))
                }
                .disabled(runner.running)
                .confirmationDialog(
                    L.t("Uninstall \(app.name)? Its wrapper AND everything installed inside (games included) will be deleted.",
                        "Désinstaller \(app.name) ? Son wrapper ET tout ce qui y est installé (jeux compris) seront supprimés."),
                    isPresented: $confirmUninstall, titleVisibility: .visible
                ) {
                    Button(L.t("Uninstall everything", "Tout désinstaller"), role: .destructive) {
                        runner.start(L.t("Uninstalling \(app.name)", "Désinstallation de \(app.name)")) { emit, doneCb in
                            WindowsApps.uninstall(app, emit: emit) { code in
                                doneCb(code)
                                if code == 0 { DispatchQueue.main.async { onRemoved() } }
                            }
                        }
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
        .task {
            reload()
            while !Task.isCancelled {
                let app = app
                running = await Task.detached { WindowsApps.isRunning(app) }.value
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
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
                                             "Choisis le programme que MacPlay doit lancer"),
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
