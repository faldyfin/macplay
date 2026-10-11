import Foundation

/// A Windows program installed from its own setup .exe, in a dedicated
/// Sikarugir wrapper next to Steam's (~/Applications/Sikarugir/<name>.app).
/// One wrapper per program keeps its prefix, engine choice and uninstall
/// independent from Steam — a launcher like TapTap installs its games there too.
struct WindowsApp: Identifiable, Hashable {
    /// The section that lists it, My Games or My Apps. A label only: it doesn't change how it runs.
    enum Category: String { case game, app }

    let name: String
    let wrapperPath: String
    var category: Category = .app
    var id: String { wrapperPath }

    var driveC: String { wrapperPath + "/Contents/SharedSupport/prefix/drive_c" }
}

enum WindowsApps {
    static let bundleIDPrefix = "com.macplay.exe."
    static let categoryKey = "MacPlay Category"
    /// The Sikarugir template's placeholder for "no program set".
    static let unsetProgram = "/nothing.exe"
    static var root: String { (Engine.wrapperPath as NSString).deletingLastPathComponent }

    static func list() -> [WindowsApp] {
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
        return entries.filter { $0.hasSuffix(".app") }.compactMap { entry in
            let path = root + "/" + entry
            guard let plist = Engine.readWrapperPlist(at: path),
                  let id = plist["CFBundleIdentifier"] as? String, id.hasPrefix(bundleIDPrefix)
            else { return nil }
            // missing or unknown = app: programs installed before categories stay in My Apps
            let category = (plist[categoryKey] as? String).flatMap(WindowsApp.Category.init(rawValue:)) ?? .app
            return WindowsApp(name: (entry as NSString).deletingPathExtension, wrapperPath: path, category: category)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: naming

    /// "TapTap_Global_PC_Setup_0.3.0.exe" -> "TapTap"
    static func suggestedName(forInstaller url: URL) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        var name = String(base.prefix { $0.isLetter || $0.isNumber })
        for suffix in ["setup", "installer", "install"]
        where name.lowercased().hasSuffix(suffix) && name.count > suffix.count {
            name = String(name.dropLast(suffix.count))
        }
        return name
    }

    /// Why `name` can't be used, or nil. The name becomes a folder name and part
    /// of pgrep patterns, so it is limited to characters that are safe in both.
    /// `current` is the app's own name when renaming: changing only its case is allowed.
    static func nameProblem(_ name: String, renaming current: String? = nil) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return L.t("Give it a name.", "Donne-lui un nom.", "Beri nama.")
        }
        if !trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == " " || $0 == "-" || $0 == "_" }) {
            return L.t("Use only letters, numbers, spaces, - and _.",
                       "Uniquement des lettres, chiffres, espaces, - et _.",
                       "Hanya huruf, angka, spasi, - dan _.")
        }
        if trimmed.lowercased() == "steam" {
            return L.t("“Steam” is reserved for MacPlay's own Steam.",
                       "« Steam » est réservé au Steam de MacPlay.",
                       "“Steam” dipakai untuk Steam milik MacPlay.")
        }
        if trimmed.lowercased() != current?.lowercased(),
           FileManager.default.fileExists(atPath: root + "/" + trimmed + ".app") {
            return L.t("An app with this name already exists.", "Une app porte déjà ce nom.", "Sudah ada app dengan nama ini.")
        }
        return nil
    }

    private static func slug(_ name: String) -> String {
        name.lowercased().map { ($0.isASCII && ($0.isLetter || $0.isNumber)) ? String($0) : "-" }.joined()
    }

    static func logPath(for app: WindowsApp) -> String {
        Engine.cachePath + "/" + app.name + "-install.log"
    }

    /// Windows Installer's own detailed log, for installs from an .msi.
    static func msiLogPath(for app: WindowsApp) -> String {
        Engine.cachePath + "/" + app.name + "-install-msi.log"
    }

    static func isPackage(_ installer: URL) -> Bool {
        installer.pathExtension.lowercased() == "msi"
    }

    /// A Mac path as Wine sees it: the template prefix maps Z: to /.
    static func windowsPath(_ path: String) -> String {
        "Z:" + path.replacingOccurrences(of: "/", with: "\\")
    }

    /// Arguments for the wrapper's wine: the setup .exe itself, or for a Windows Installer
    /// package, msiexec with its full interface and a detailed log. msiexec passes the
    /// package path on as given, so both paths are absolute Windows paths.
    static func installerArguments(for installer: URL, msiLog: String) -> [String] {
        guard isPackage(installer) else { return [installer.path] }
        return ["msiexec", "/i", windowsPath(installer.path), "/l*v", windowsPath(msiLog)]
    }

    // MARK: install

    static func install(installer: URL, name: String, category: WindowsApp.Category,
                        emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try runInstall(installer: installer, name: name.trimmingCharacters(in: .whitespaces),
                               category: category, emit: emit)
                done(0)
            } catch {
                emit("✗ \(error.localizedDescription)")
                done(1)
            }
        }
    }

    private static func runInstall(installer: URL, name: String, category: WindowsApp.Category,
                                   emit: (String) -> Void) throws {
        if let problem = nameProblem(name) { throw Engine.fail(problem) }
        let app = WindowsApp(name: name, wrapperPath: root + "/" + name + ".app", category: category)

        try Engine.downloadToCache(Engine.wrapperDownloads + [Engine.winetricksDownload], emit: emit)
        try Engine.assembleWrapper(at: app.wrapperPath, emit: emit)

        // tag it right away so a half-finished install still shows up and can be uninstalled
        try updatePlist(of: app) { plist in
            plist["CFBundleName"] = name
            plist["CFBundleIdentifier"] = bundleIDPrefix + slug(name)
            Engine.setBackend("d3dmetal", in: &plist)
            plist[categoryKey] = category.rawValue
        }

        // A fresh prefix has no font files in C:\windows\Fonts; Heartopia (Unity) drew
        // all its UI text blank until these were installed.
        emit(L.t("Installing the Windows core fonts (Arial, Verdana…), ~1 min…",
                 "Installation des polices Windows de base (Arial, Verdana…), ~1 min…",
                 "Menginstal font inti Windows (Arial, Verdana…), ~1 menit…"))
        let fontsEnv = Engine.wineEnv(for: app.wrapperPath).merging(["WINEDLLOVERRIDES": "winemenubuilder.exe=d"]) { _, new in new }
        let fonts = Engine.sh("/bin/sh", [Engine.cachePath + "/" + Engine.winetricksDownload.name, "-q", "corefonts"],
                              env: fontsEnv)
        if fonts.code != 0 {
            emit(L.t("Core fonts could not be installed — some games may show no text.",
                     "Les polices de base n'ont pas pu être installées — certains jeux risquent de n'afficher aucun texte.",
                     "Font inti gagal diinstal — beberapa game mungkin tidak menampilkan teks."))
        }
        _ = standInForSegoeUI(wrapper: app.wrapperPath, env: fontsEnv)

        let before = exeFiles(in: app.driveC)
        emit(L.t("Running the installer — follow its window. MacPlay waits until it closes.",
                 "Lancement de l'installeur — suis sa fenêtre. MacPlay attend qu'il se ferme.",
                 "Menjalankan installer — ikuti jendelanya. MacPlay menunggu sampai ditutup."))
        let code = try runInstaller(installer, in: app)
        let added = exeFiles(in: app.driveC).subtracting(before)
        let installLog = isPackage(installer) ? msiLogPath(for: app) : logPath(for: app)

        let consoles = Set(added.filter { isConsoleProgram(atPath: app.driveC + $0) })
        guard let program = pickMainProgram(Array(added), appName: name, consolePrograms: consoles) else {
            throw Engine.fail(L.t("No installed program found (installer exit code \(code)). If you cancelled the installer, uninstall this app and try again; otherwise pick the program with “Change…”. Log: \(installLog)",
                                  "Aucun programme installé trouvé (code de sortie \(code)). Si tu as annulé l'installeur, désinstalle cette app et réessaie ; sinon choisis le programme avec « Changer… ». Journal : \(installLog)",
                                  "Tidak ada program terinstal yang ditemukan (kode keluar installer \(code)). Kalau kamu membatalkan installer, hapus app ini lalu coba lagi; kalau tidak, pilih programnya lewat “Ganti…”. Log: \(installLog)"))
        }
        try updatePlist(of: app) { $0["Program Name and Path"] = program }
        emit(L.t("Program found: \(program)", "Programme trouvé : \(program)", "Program ditemukan: \(program)"))

        // not isRunning(): wineserver outlives the installer by a few seconds.
        // Windows paths show up in the process args; wildcard the separators.
        let programPattern = program.map { $0.isLetter || $0.isNumber ? String($0) : "." }.joined()
        if Engine.processAlive(programPattern) {
            emit(L.t("The installer left it running. Stop it and launch it from MacPlay so the graphics engine applies to it and its games.",
                     "L'installeur l'a laissé ouvert. Arrête-le puis lance-le depuis MacPlay pour que le moteur graphique s'applique à lui et à ses jeux.",
                     "Installer membiarkannya tetap berjalan. Hentikan lalu jalankan dari MacPlay supaya engine grafis berlaku untuknya dan game-gamenya."))
        }
    }

    /// Segoe UI, the Windows interface font, can't be redistributed. .NET programs that ask
    /// for it by name stop at startup without it (IAP Desktop: "FontFamily could not be
    /// found"), so Wine draws Tahoma, which it ships, in its place.
    static func standInForSegoeUI(wrapper: String, env: [String: String]) -> Bool {
        Engine.sh(wrapper + "/Contents/SharedSupport/wine/bin/wine",
                  ["reg", "add", "HKCU\\Software\\Wine\\Fonts\\Replacements", "/v", "Segoe UI",
                   "/t", "REG_SZ", "/d", "Tahoma", "/f"],
                  env: env).code == 0
    }

    /// Runs the setup with the wrapper's own wine (no graphics backend needed).
    /// Waits for the installer process only — it may start the program it just
    /// installed, which must not block us. Output goes to a file rather than a
    /// pipe for the same reason: that program would inherit the pipe and hold it open.
    private static func runInstaller(_ installer: URL, in app: WindowsApp) throws -> Int32 {
        let logFile = logPath(for: app)
        FileManager.default.createFile(atPath: logFile, contents: nil)
        let log = FileHandle(forWritingAtPath: logFile)
        defer { try? log?.close() }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: app.wrapperPath + "/Contents/SharedSupport/wine/bin/wine")
        p.arguments = installerArguments(for: installer, msiLog: msiLogPath(for: app))
        p.currentDirectoryURL = installer.deletingLastPathComponent()
        var env = ProcessInfo.processInfo.environment.merging(Engine.wineEnv(for: app.wrapperPath)) { _, new in new }
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"  // no host menu entries outside the wrapper
        p.environment = env
        p.standardOutput = log ?? FileHandle.nullDevice
        p.standardError = log ?? FileHandle.nullDevice
        try p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    /// .exe files under drive_c, as drive_c-relative paths ("/Program Files/X/x.exe").
    /// Skips `windows` and symlinks: the user folders link to the real ~/Documents,
    /// ~/Downloads etc., which must not be crawled.
    static func exeFiles(in driveC: String) -> Set<String> {
        let rootURL = URL(fileURLWithPath: driveC)
        guard let walker = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: [.isSymbolicLinkKey])
        else { return [] }
        var found = Set<String>()
        for case let url as URL in walker {
            let relative = String(url.path.dropFirst(rootURL.path.count))
            let isLink = (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
            if isLink || relative.lowercased() == "/windows" {
                walker.skipDescendants()
                continue
            }
            if url.pathExtension.lowercased() == "exe" { found.insert(relative) }
        }
        return found
    }

    /// Best guess at the program an installer added: skip uninstallers, updaters
    /// and crash reporters, prefer a file named like the app, then a windowed program
    /// over a console tool (7-Zip's package installs 7z.exe next to 7zFM.exe), then
    /// the shallowest.
    static func pickMainProgram(_ candidates: [String], appName: String,
                                consolePrograms: Set<String> = []) -> String? {
        let noise = ["unins", "setup", "install", "update", "crash", "report", "helper", "redist", "elevate"]
        let key = appName.lowercased().filter { $0.isLetter || $0.isNumber }
        func fileKey(_ path: String) -> String {
            ((path as NSString).lastPathComponent as NSString).deletingPathExtension.lowercased()
        }
        let usable = candidates.filter { path in !noise.contains { fileKey(path).contains($0) } }
        func rank(_ path: String) -> (Int, Int, Int, String) {
            let nameMatch = !key.isEmpty && fileKey(path).filter { $0.isLetter || $0.isNumber }.contains(key)
            return (nameMatch ? 0 : 1, consolePrograms.contains(path) ? 1 : 0, path.split(separator: "/").count, path)
        }
        return usable.min { rank($0) < rank($1) }
    }

    /// Whether a Windows executable is a console program, from the Subsystem field of
    /// its PE header (3 = console, 2 = windowed; at offset 68 of the optional header in
    /// both 32- and 64-bit files). Anything unreadable counts as windowed.
    static func isConsoleProgram(atPath path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? handle.close() }
        guard let dos = try? handle.read(upToCount: 64).map(Array.init), dos.count == 64,
              dos[0] == 0x4D, dos[1] == 0x5A else { return false }  // "MZ"
        let peOffset = dos[0x3C...0x3F].reversed().reduce(0) { $0 << 8 | Int($1) }
        guard (try? handle.seek(toOffset: UInt64(peOffset))) != nil,
              let pe = try? handle.read(upToCount: 24 + 70).map(Array.init), pe.count == 24 + 70,
              pe[0..<4] == [0x50, 0x45, 0, 0] else { return false }  // "PE\0\0"
        let subsystem = Int(pe[24 + 68]) | Int(pe[24 + 69]) << 8
        return subsystem == 3
    }

    // MARK: settings

    private static func updatePlist(of app: WindowsApp, _ change: (inout [String: Any]) -> Void) throws {
        guard var plist = Engine.readWrapperPlist(at: app.wrapperPath) else {
            throw Engine.fail(L.t("Wrapper not found.", "Wrapper introuvable.", "Wrapper tidak ditemukan."))
        }
        change(&plist)
        try Engine.writeWrapperPlist(plist, at: app.wrapperPath)
    }

    static func programPath(of app: WindowsApp) -> String? {
        guard let path = Engine.readWrapperPlist(at: app.wrapperPath)?["Program Name and Path"] as? String,
              path != unsetProgram
        else { return nil }
        return path
    }

    /// For a file picked in Finder: it must live inside this app's C: drive.
    static func setProgram(file: URL, for app: WindowsApp) throws {
        let drive = URL(fileURLWithPath: app.driveC).resolvingSymlinksInPath().path
        let path = file.resolvingSymlinksInPath().path
        guard path.hasPrefix(drive + "/") else {
            throw Engine.fail(L.t("Pick a program inside this app's C: drive.",
                                  "Choisis un programme dans le disque C: de cette app.",
                                  "Pilih program di dalam drive C: milik app ini."))
        }
        let relative = String(path.dropFirst(drive.count))
        try updatePlist(of: app) { $0["Program Name and Path"] = relative }
    }

    static func setCategory(_ category: WindowsApp.Category, for app: WindowsApp) throws {
        try updatePlist(of: app) { $0[categoryKey] = category.rawValue }
    }

    static func programFlags(of app: WindowsApp) -> String {
        (Engine.readWrapperPlist(at: app.wrapperPath)?["Program Flags"] as? String) ?? ""
    }

    static func setProgramFlags(_ flags: String, for app: WindowsApp) throws {
        try updatePlist(of: app) { $0["Program Flags"] = flags }
    }

    // MARK: run

    /// Any wine process of this wrapper — the program itself or a game it started.
    static func isRunning(_ app: WindowsApp) -> Bool {
        Engine.processAlive(app.wrapperPath + ".*wineserver")
    }

    /// Opening the wrapper lets its launcher start the program with the chosen engine.
    static func launch(_ app: WindowsApp) {
        GameDisplay.prepareForLaunch()
        Engine.sh("/usr/bin/open", [app.wrapperPath])
    }

    static func stop(_ app: WindowsApp) {
        Engine.sh(app.wrapperPath + "/Contents/MacOS/wineskinlauncher", ["WSS-wineserverkill"])
    }

    /// Renames the wrapper folder, bundle name and id. The app must be stopped:
    /// a running Wine session keeps using the old path.
    static func rename(_ app: WindowsApp, to newName: String) throws -> WindowsApp {
        let name = newName.trimmingCharacters(in: .whitespaces)
        if isRunning(app) {
            throw Engine.fail(L.t("Stop \(app.name) before renaming it.", "Arrête \(app.name) avant de le renommer.", "Hentikan \(app.name) sebelum mengganti namanya."))
        }
        if let problem = nameProblem(name, renaming: app.name) { throw Engine.fail(problem) }

        let renamed = WindowsApp(name: name, wrapperPath: root + "/" + name + ".app", category: app.category)
        let fm = FileManager.default
        // via a temporary name, so a case-only change also works on a case-insensitive disk
        let temp = root + "/." + UUID().uuidString + ".app"
        try fm.moveItem(atPath: app.wrapperPath, toPath: temp)
        do {
            try fm.moveItem(atPath: temp, toPath: renamed.wrapperPath)
        } catch {
            try? fm.moveItem(atPath: temp, toPath: app.wrapperPath)
            throw error
        }
        try updatePlist(of: renamed) { plist in
            plist["CFBundleName"] = name
            plist["CFBundleIdentifier"] = bundleIDPrefix + slug(name)
        }
        let oldKey = PlayTime.appKey(app.name), newKey = PlayTime.appKey(name)
        ChosenArt.shared.move(from: oldKey, to: newKey)
        PlayTime.shared.rename(from: oldKey, to: newKey)
        return renamed
    }

    static func uninstall(_ app: WindowsApp, emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            emit(L.t("Stopping \(app.name)…", "Arrêt de \(app.name)…", "Menghentikan \(app.name)…"))
            stop(app)
            Thread.sleep(forTimeInterval: 3)
            emit(L.t("Deleting the wrapper and everything installed inside…",
                     "Suppression du wrapper et de tout ce qui y est installé…",
                     "Menghapus wrapper dan semua yang terinstal di dalamnya…"))
            try? FileManager.default.removeItem(atPath: app.wrapperPath)
            let gone = !FileManager.default.fileExists(atPath: app.wrapperPath)
            if gone { ChosenArt.shared.removeAll(for: PlayTime.appKey(app.name)) }
            emit(gone ? L.t("\(app.name) is uninstalled.", "\(app.name) est désinstallé.", "\(app.name) sudah dihapus.")
                      : L.t("Could not delete the wrapper.", "Impossible de supprimer le wrapper.", "Wrapper tidak bisa dihapus."))
            done(gone ? 0 : 1)
        }
    }
}
