import Foundation
import AppKit
import CryptoKit

// MARK: - Models (mirror data/games.json)

struct HardwareProfile {
    let chip: String
    let tier: String
    let ramGB: Int
    let gpuCores: Int?
    let macosVersion: String
    let rosetta: Bool
    let appleSilicon: Bool
}

struct TierSettings: Codable {
    let preset: String
    let upscaling: String
    let extra: String?
}

struct GameFix: Codable, Hashable {
    let symptom: String
    let fix: String
    let symptom_fr: String?
    let fix_fr: String?

    var localizedSymptom: String { L.fr ? (symptom_fr ?? symptom) : symptom }
    var localizedFix: String { L.fr ? (fix_fr ?? fix) : fix }
}

struct GameEntry: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let steam_appid: Int?
    let status: String
    let backend: String
    let dx: String?
    let ram_min_gb: Int?
    let launch_options: String?
    let notes: String?
    let notes_fr: String?
    let settings: [String: TierSettings]?
    let fixes: [GameFix]?
    // added by tools/update_compat.py; absent in the curated data/games.json
    let source: String?            // "macplay", "applegamingwiki" or "areweanticheatyet"
    let source_url: String?
    let wiki_rating: String?       // AppleGamingWiki: perfect, playable, runs, menu, unplayable
    let wiki_method: String?       // "crossover" or "wine"
    let wiki_reported: String?     // date of the latest report (YYYY-MM-DD), if any
    let wiki_url: String?
    let anticheat_status: String?  // AreWeAntiCheatYet, Linux/Proton: Supported, Running, Broken, Denied
    let anticheats: [String]?
    let anticheat_url: String?

    /// Hand-maintained by MacPlay (engine, presets, fixes) rather than imported.
    var isCurated: Bool { source == nil || source == "macplay" }

    var localizedNotes: String? {
        let n = L.fr ? (notes_fr ?? notes) : notes
        return (n?.isEmpty ?? true) ? nil : n
    }

    static func == (lhs: GameEntry, rhs: GameEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct GamesFile: Codable {
    let games: [GameEntry]
    let generated_at: String?
}

struct DoctorReport {
    let profile: HardwareProfile
    let swapUsedGB: Double
    let swapTotalGB: Double
    let diskFreeGB: Double

    var swapSaturated: Bool { swapTotalGB > 0 && swapUsedGB / swapTotalGB > 0.75 }
}

struct SteamStatus {
    let installed: Bool
    let running: Bool
    let engineVersion: String?
    let backend: String
}

// MARK: - Native engine (no external runtime needed)

enum Engine {
    static let wrapperPath = NSHomeDirectory() + "/Applications/Sikarugir/Steam.app"
    static let cachePath = NSHomeDirectory() + "/Library/Caches/macplay"

    /// A cached download. The file name carries the version so a bump never reuses
    /// an old cache entry. `sha256` is nil only where the vendor serves nothing but
    /// "latest" (SteamSetup.exe).
    struct Download {
        let name: String
        let url: String
        let sha256: String?
    }

    static let templateDownload = Download(
        name: "Template-1.0.20.tar.xz",
        url: "https://github.com/Sikarugir-App/Wrapper/releases/download/v1.0/Template-1.0.20.tar.xz",
        sha256: "68bcaa9e6de4732bcb2eca9700ed12d1d0857b1748d60494911a19e17dd9b962")
    static let engineDownload = Download(
        name: "WS12WineSikarugir11.0.tar.xz",
        url: "https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0.tar.xz",
        sha256: "dcb3de3acab2eaf37591768dc7f6f6c20fa8e6b69c88ddd61e63798c02befcf9")
    static let winetricksDownload = Download(
        name: "winetricks-f3890f67",
        url: "https://raw.githubusercontent.com/Sikarugir-App/winetricks/f3890f670867b5ffbc3938726db45c0f7d16c8ba/src/winetricks",
        sha256: "672a1ff4442e8691a3ffc0e6860137e201a1d1227e9b3044245f1731e9e9837e")
    static let steamSetupDownload = Download(
        name: "SteamSetup.exe",
        url: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe",
        sha256: nil)
    static let steamFlags = "-allosarches -cef-force-32bit -cef-in-process-gpu -cef-disable-sandbox"

    static let backendKeys = ["d3dmetal": "D3DMETAL", "dxmt": "DXMT", "dxvk": "DXVK"]

    // MARK: shell helper (system binaries only — present on every Mac)

    @discardableResult
    static func sh(_ path: String, _ args: [String], env extraEnv: [String: String] = [:]) -> (code: Int32, out: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        if !extraEnv.isEmpty {
            p.environment = ProcessInfo.processInfo.environment.merging(extraEnv) { _, new in new }
        }
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (-1, "\(error.localizedDescription)") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    // MARK: data

    static func loadGames() -> [GameEntry] {
        CompatDB.load()?.games ?? []
    }

    // MARK: detect

    static func detect() -> HardwareProfile {
        let chip = sh("/usr/sbin/sysctl", ["-n", "machdep.cpu.brand_string"]).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let ramBytes = Int64(sh("/usr/sbin/sysctl", ["-n", "hw.memsize"]).out
            .trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        var tier = "base"
        for t in ["Pro", "Max", "Ultra"] where chip.hasSuffix(t) { tier = t.lowercased() }

        var gpuCores: Int? = nil
        let disp = sh("/usr/sbin/system_profiler", ["SPDisplaysDataType", "-json"]).out
        if let data = disp.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let displays = json["SPDisplaysDataType"] as? [[String: Any]],
           let first = displays.first {
            if let s = first["sppci_cores"] as? String { gpuCores = Int(s) }
            if let i = first["sppci_cores"] as? Int { gpuCores = i }
        }

        let v = ProcessInfo.processInfo.operatingSystemVersion
        let rosetta = FileManager.default.fileExists(atPath: "/Library/Apple/usr/libexec/oah")
            || sh("/usr/bin/pgrep", ["-q", "oahd"]).code == 0

        return HardwareProfile(
            chip: chip,
            tier: tier,
            ramGB: Int((Double(ramBytes) / 1_073_741_824.0).rounded()),
            gpuCores: gpuCores,
            macosVersion: "\(v.majorVersion).\(v.minorVersion)",
            rosetta: rosetta,
            appleSilicon: chip.hasPrefix("Apple")
        )
    }

    // MARK: doctor

    static func doctor() -> DoctorReport {
        let profile = detect()

        var swapUsed = 0.0, swapTotal = 0.0
        let swap = sh("/usr/sbin/sysctl", ["-n", "vm.swapusage"]).out
        if let m = swap.range(of: #"total = ([\d.]+)M"#, options: .regularExpression) {
            swapTotal = (Double(swap[m].dropFirst(8).dropLast(1)) ?? 0) / 1024
        }
        if let m = swap.range(of: #"used = ([\d.]+)M"#, options: .regularExpression) {
            swapUsed = (Double(swap[m].dropFirst(7).dropLast(1)) ?? 0) / 1024
        }

        var diskFree = 0.0
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let free = attrs[.systemFreeSize] as? Int64 {
            diskFree = Double(free) / 1_073_741_824.0
        }

        return DoctorReport(
            profile: profile,
            swapUsedGB: swapUsed, swapTotalGB: swapTotal,
            diskFreeGB: diskFree
        )
    }

    static func steamStatus() -> SteamStatus {
        let installed = wrapperInstalled
        let engineVersion = installed
            ? (try? String(contentsOfFile: wrapperPath + "/Contents/SharedSupport/wine/version", encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            : nil
        return SteamStatus(installed: installed,
                           running: installed && steamUIAlive,
                           engineVersion: engineVersion,
                           backend: activeBackend(of: wrapperPath).uppercased())
    }

    static var wrapperInstalled: Bool {
        FileManager.default.fileExists(atPath: wrapperPath + "/Contents/Info.plist")
    }

    // MARK: wrapper plist

    static func readWrapperPlist(at wrapper: String = wrapperPath) -> [String: Any]? {
        guard let data = FileManager.default.contents(atPath: wrapper + "/Contents/Info.plist") else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }

    static func writeWrapperPlist(_ plist: [String: Any], at wrapper: String = wrapperPath) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: wrapper + "/Contents/Info.plist"))
    }

    /// Templates up to 1.0.11 have a DXMT switch and fall back to WineD3D with every
    /// switch off. Newer ones (1.0.20 checked) dropped the DXMT key: DXMT is what runs
    /// when D3DMetal and DXVK are both off, and WineD3D is no longer offered.
    private static func hasLegacyBackendSwitches(_ plist: [String: Any]) -> Bool {
        plist["DXMT"] != nil
    }

    static func backendChoices(for wrapper: String) -> [(id: String, label: String)] {
        let choices = [(id: "d3dmetal", label: "D3DMetal"), (id: "dxmt", label: "DXMT"), (id: "dxvk", label: "DXVK")]
        let legacy = readWrapperPlist(at: wrapper).map(hasLegacyBackendSwitches) ?? false
        return legacy ? choices + [(id: "wined3d", label: "WineD3D")] : choices
    }

    /// Set the graphics backend toggles in a wrapper plist. Returns the backend that will run.
    @discardableResult
    static func setBackend(_ backend: String, in plist: inout [String: Any]) -> String {
        if hasLegacyBackendSwitches(plist) {
            for key in backendKeys.values { plist[key] = 0 }
            if let key = backendKeys[backend] { plist[key] = 1 }
            plist["MOLTENVKCX"] = 1
            return backendKeys[backend] ?? "WineD3D"
        }
        plist["D3DMETAL"] = backend == "d3dmetal" ? 1 : 0
        plist["DXVK"] = backend == "dxvk" ? 1 : 0
        return backend == "d3dmetal" ? "D3DMETAL" : backend == "dxvk" ? "DXVK" : "DXMT"
    }

    static func applyBackend(_ backend: String, wrapper: String = wrapperPath) throws -> String {
        guard var plist = readWrapperPlist(at: wrapper) else {
            throw fail(wrapper == wrapperPath
                       ? L.t("Wrapper not found — install Steam first.", "Wrapper introuvable — installe Steam d'abord.")
                       : L.t("Wrapper not found.", "Wrapper introuvable."))
        }
        let applied = setBackend(backend, in: &plist)
        try writeWrapperPlist(plist, at: wrapper)
        return applied
    }

    // MARK: process helpers

    static var prefixPath: String { wrapperPath + "/Contents/SharedSupport/prefix" }
    static var winePath: String { wrapperPath + "/Contents/SharedSupport/wine/bin/wine" }

    static func processAlive(_ pattern: String) -> Bool {
        sh("/usr/bin/pgrep", ["-f", pattern]).code == 0
    }

    /// The Steam UI (CEF helper) only runs when the client is actually up.
    static var steamUIAlive: Bool { processAlive("steamwebhelper") }

    /// True while Steam is downloading/installing something: the `downloading`
    /// folder holds partial data, or a manifest is in a non-"fully installed"
    /// (StateFlags 4) state. Restarting Steam mid-download can make it discard
    /// the partial, so callers must never kill the session while this is true.
    static var downloadInProgress: Bool {
        let steamapps = prefixPath + "/drive_c/Program Files (x86)/Steam/steamapps"
        let dl = steamapps + "/downloading"
        if let items = try? FileManager.default.contentsOfDirectory(atPath: dl),
           items.contains(where: { $0 != ".DS_Store" }) {
            return true
        }
        for f in (try? FileManager.default.contentsOfDirectory(atPath: steamapps)) ?? []
        where f.hasPrefix("appmanifest_") && f.hasSuffix(".acf") {
            if let text = try? String(contentsOfFile: steamapps + "/" + f, encoding: .utf8),
               let m = text.range(of: #""StateFlags"\s*"(\d+)""#, options: .regularExpression),
               let flags = Int(text[m].components(separatedBy: "\"").dropLast().last ?? ""),
               flags != 4 {  // 4 = fully installed and idle
                return true
            }
        }
        return false
    }

    /// Backend currently active in the Steam wrapper ("d3dmetal", "dxmt", "dxvk" or "wined3d").
    static var activeBackend: String { activeBackend(of: wrapperPath) }

    static func activeBackend(of wrapper: String) -> String {
        guard let plist = readWrapperPlist(at: wrapper) else { return "wined3d" }
        func isOn(_ key: String) -> Bool { (plist[key] as? Int) == 1 || (plist[key] as? Bool) == true }
        if isOn("D3DMETAL") { return "d3dmetal" }
        if isOn("DXVK") { return "dxvk" }
        if isOn("DXMT") || !hasLegacyBackendSwitches(plist) { return "dxmt" }
        return "wined3d"
    }

    // MARK: long-running actions (emit log lines, then completion code)

    /// Boot the wrapper's Steam with extra command-line arguments.
    /// Under Wine, a second steam.exe does NOT forward commands to the running
    /// instance (verified), so the reliable path is: temporarily append the
    /// arguments to the wrapper's launch flags, (re)start Steam through its own
    /// launcher (which sets up the full backend env), then restore the flags.
    static func bootSteam(extraArgs: String, emit: (String) -> Void) -> Bool {
        guard wrapperInstalled, var plist = readWrapperPlist() else {
            emit(L.t("Steam is not installed.", "Steam n'est pas installé."))
            return false
        }
        let originalFlags = (plist["Program Flags"] as? String) ?? steamFlags

        // Never kill Steam mid-download — it would discard the partial data.
        if steamUIAlive && downloadInProgress {
            emit(L.t("A download is in progress in Steam — not restarting it. Try again once the download is finished.",
                     "Un téléchargement est en cours dans Steam — je ne le redémarre pas. Réessaie une fois le téléchargement terminé."))
            return false
        }

        if steamUIAlive {
            emit(L.t("Restarting Steam…", "Redémarrage de Steam…"))
            sh(wrapperPath + "/Contents/MacOS/wineskinlauncher", ["WSS-wineserverkill"])
            Thread.sleep(forTimeInterval: 3)
        } else {
            emit(L.t("Starting Steam…", "Démarrage de Steam…"))
        }

        plist["Program Flags"] = originalFlags + " " + extraArgs
        do { try writeWrapperPlist(plist) } catch {
            emit(error.localizedDescription)
            return false
        }

        func restoreFlags() {
            if var p = readWrapperPlist() {
                p["Program Flags"] = originalFlags
                try? writeWrapperPlist(p)
            }
        }

        GameDisplay.prepareForLaunch()
        sh("/usr/bin/open", [wrapperPath])

        // Restore the flags only once steam.exe is visibly running WITH our
        // extra args — restoring earlier races the launcher's plist read
        // (cold boots can take minutes).
        let argPattern = extraArgs.map { $0.isLetter || $0.isNumber ? String($0) : "." }.joined()
        var argsConsumed = false
        var waited = 0
        while waited < 240 {
            if processAlive(argPattern) { argsConsumed = true; break }
            Thread.sleep(forTimeInterval: 3)
            waited += 3
        }
        restoreFlags()
        guard argsConsumed else {
            emit(L.t("Steam did not start in time.", "Steam n'a pas démarré à temps."))
            return false
        }

        waited = 0
        while !steamUIAlive && waited < 120 {
            Thread.sleep(forTimeInterval: 3)
            waited += 3
        }
        guard steamUIAlive else {
            emit(L.t("Steam did not start.", "Steam n'a pas démarré."))
            return false
        }
        return true
    }

    static func launchGameSync(appid: String, emit: (String) -> Void) -> Bool {
        guard bootSteam(extraArgs: "-applaunch " + appid, emit: emit) else { return false }
        emit(L.t("Steam is up — the game is launching (first launch can take a while: updates, shaders)…",
                 "Steam est lancé — le jeu démarre (le premier lancement peut être long : mises à jour, shaders)…"))
        return true
    }

    /// Trigger a game install.
    /// Wine can't inject a steam:// command into an already-running Steam
    /// (verified: neither a second steam.exe nor `wine start` reaches it), and
    /// restarting Steam would abort any download in progress. So:
    ///   - Steam down  -> boot it with steam://install (opens the confirm dialog)
    ///   - Steam up     -> bring it to front and let the user add the game there
    ///                     (this is how Steam queues multiple downloads anyway)
    static func installGame(appid: String, gameTitle: String,
                            emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if steamUIAlive {
                sh("/usr/bin/open", [wrapperPath])  // focus the Steam window
                emit(L.t("Steam is already open. In its window, go to your Library, find “\(gameTitle)” and click Install — it will queue up next to any current download.",
                         "Steam est déjà ouvert. Dans sa fenêtre, va dans ta Bibliothèque, cherche « \(gameTitle) » et clique Installer — il se mettra en file d'attente à côté du téléchargement en cours."))
                done(0)
                return
            }
            let ok = bootSteam(extraArgs: "steam://install/" + appid, emit: emit)
            if ok {
                emit(L.t("Steam is showing the install window — confirm it there. Once installed, the game appears in “My games”.",
                         "Steam affiche la fenêtre d'installation — confirme là-bas. Une fois installé, le jeu apparaît dans « Mes jeux »."))
            }
            done(ok ? 0 : 1)
        }
    }

    static func uninstallSteam(emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard wrapperInstalled else { done(0); return }
            emit(L.t("Stopping the Wine session…", "Arrêt de la session Wine…"))
            sh(wrapperPath + "/Contents/MacOS/wineskinlauncher", ["WSS-wineserverkill"])
            Thread.sleep(forTimeInterval: 3)
            emit(L.t("Deleting the wrapper and everything inside…",
                     "Suppression du wrapper et de tout son contenu…"))
            try? FileManager.default.removeItem(atPath: wrapperPath)
            let gone = !wrapperInstalled
            emit(gone ? L.t("Steam is uninstalled.", "Steam est désinstallé.")
                      : L.t("Could not delete the wrapper.", "Impossible de supprimer le wrapper."))
            done(gone ? 0 : 1)
        }
    }

    static func reinstallSteam(emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        uninstallSteam(emit: emit) { code in
            guard code == 0 else { done(code); return }
            setupSteam(emit: emit, done: done)
        }
    }

    /// Opening the wrapper lets its launcher start Steam with the chosen graphics engine.
    static func launchSteam() {
        GameDisplay.prepareForLaunch()
        sh("/usr/bin/open", [wrapperPath])
    }

    static func stopSteam(emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            emit(L.t("Stopping Steam and everything it started…", "Arrêt de Steam et de tout ce qu'il a lancé…"))
            sh(wrapperPath + "/Contents/MacOS/wineskinlauncher", ["WSS-wineserverkill"])
            Thread.sleep(forTimeInterval: 3)
            done(steamUIAlive ? 1 : 0)
        }
    }

    static func restart(emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            emit(L.t("Stopping the Wine session…", "Arrêt de la session Wine…"))
            sh(wrapperPath + "/Contents/MacOS/wineskinlauncher", ["WSS-wineserverkill"])
            Thread.sleep(forTimeInterval: 3)
            emit(L.t("Relaunching Steam…", "Relance de Steam…"))
            GameDisplay.prepareForLaunch()
            sh("/usr/bin/open", [wrapperPath])
            done(0)
        }
    }

    static func setupSteam(emit: @escaping (String) -> Void, done: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try runSetup(emit: emit)
                done(0)
            } catch {
                emit("✗ \(error.localizedDescription)")
                done(1)
            }
        }
    }

    static func fail(_ message: String) -> NSError {
        NSError(domain: "macplay", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// What every wrapper is built from (Steam's and each Windows app's).
    static let wrapperDownloads = [templateDownload, engineDownload]

    /// Fetch files into the cache once (curl ships with macOS), checking each
    /// against its pinned SHA-256 — cache hits included.
    static func downloadToCache(_ files: [Download], emit: (String) -> Void) throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        for file in files {
            let name = file.name
            let dest = cachePath + "/" + name
            if fm.fileExists(atPath: dest) {
                if matchesDigest(dest, file.sha256) {
                    emit(L.t("Cached: \(name)", "En cache : \(name)"))
                    continue
                }
                try fm.removeItem(atPath: dest)  // corrupted or altered: fetch it again
            }
            emit(L.t("Downloading \(name)…", "Téléchargement de \(name)…"))
            // unique partial name: two setups may fetch the same file at once
            let part = dest + "." + UUID().uuidString + ".part"
            let r = sh("/usr/bin/curl", ["-sL", "--fail", "-o", part, file.url])
            guard r.code == 0 else {
                try? fm.removeItem(atPath: part)
                throw fail(L.t("Download failed: \(name)", "Échec du téléchargement : \(name)"))
            }
            guard matchesDigest(part, file.sha256) else {
                try? fm.removeItem(atPath: part)
                throw fail(L.t("Checksum mismatch for \(name) — refusing to use it.",
                               "Somme de contrôle invalide pour \(name) — fichier refusé."))
            }
            if fm.fileExists(atPath: dest) {
                try? fm.removeItem(atPath: part)
            } else {
                try fm.moveItem(atPath: part, toPath: dest)
            }
        }
    }

    /// True when the file matches `expected`, or when there is no digest to check.
    private static func matchesDigest(_ path: String, _ expected: String?) -> Bool {
        guard let expected else { return true }
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined() == expected
    }

    /// Environment for running a wrapper's wine directly, outside its launcher.
    /// Mirrors what the launcher sets for the Wine 11 engine: its wineserver has no
    /// LC_RPATH, so it needs the library fallback path, and the engine only starts
    /// Windows programs with SikarugirAppWine11=1. macOS strips DYLD_* when a shell
    /// starts, so winetricks gets the path as WINETRICKS_FALLBACK_LIBRARY_PATH and
    /// re-exports it itself.
    static func wineEnv(for wrapper: String) -> [String: String] {
        let wine = wrapper + "/Contents/SharedSupport/wine"
        let frameworks = wrapper + "/Contents/Frameworks"
        let libraries = [wine + "/lib", wine + "/lib64", frameworks, frameworks + "/GStreamer.framework/Libraries",
                         "/usr/lib", "/usr/libexec", "/usr/lib/system"].joined(separator: ":")
        return [
            "WINEPREFIX": wrapper + "/Contents/SharedSupport/prefix",
            "WINE": wine + "/bin/wine",
            "WINESERVER": wine + "/bin/wineserver",
            "DYLD_FALLBACK_LIBRARY_PATH": libraries,
            "WINETRICKS_FALLBACK_LIBRARY_PATH": libraries,
            "SikarugirAppWine11": "1",
            "PATH": wine + "/bin:" + wrapper + "/Contents/Configure.app/Contents/Resources:"
                + (ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"),
        ]
    }

    /// Build an empty wrapper (template + Wine engine + fresh prefix) at `wrapper`.
    /// `wrapperDownloads` must already be in the cache.
    static func assembleWrapper(at wrapper: String, emit: (String) -> Void) throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: (wrapper as NSString).deletingLastPathComponent,
                               withIntermediateDirectories: true)

        emit(L.t("Assembling the wrapper…", "Assemblage du wrapper…"))
        let wrapperName = ((wrapper as NSString).lastPathComponent as NSString).deletingPathExtension
        let work = cachePath + "/work-" + wrapperName
        try? fm.removeItem(atPath: work)
        try fm.createDirectory(atPath: work, withIntermediateDirectories: true)
        guard sh("/usr/bin/tar", ["-xf", cachePath + "/" + templateDownload.name, "-C", work]).code == 0
        else { throw fail("tar template") }
        guard let appName = try fm.contentsOfDirectory(atPath: work).first(where: { $0.hasSuffix(".app") })
        else { throw fail("template .app not found") }
        try fm.moveItem(atPath: work + "/" + appName, toPath: wrapper)

        guard sh("/usr/bin/tar", ["-xf", cachePath + "/" + engineDownload.name, "-C", work]).code == 0
        else { throw fail("tar engine") }
        let wineDst = wrapper + "/Contents/SharedSupport/wine"
        try? fm.removeItem(atPath: wineDst)
        try fm.moveItem(atPath: work + "/wswine.bundle", toPath: wineDst)
        sh("/usr/bin/xattr", ["-drs", "com.apple.quarantine", wrapper])

        // wine prefix — the launcher idles in its GUI event loop after the work
        // is done, so poll for completion and terminate it ourselves
        emit(L.t("Creating the Wine prefix (1-2 min)…", "Création du prefix Wine (1-2 min)…"))
        let prefix = wrapper + "/Contents/SharedSupport/prefix"
        try runLauncherStep(wrapper: wrapper, arg: "WSS-wineprefixcreate", doneCheck: {
            fm.fileExists(atPath: prefix + "/system.reg")
                && fm.fileExists(atPath: prefix + "/user.reg")
                && sh("/usr/bin/pgrep", ["-f", wrapper + ".*wineserver"]).code != 0
        })
    }

    private static func runSetup(emit: (String) -> Void) throws {
        let fm = FileManager.default
        guard !wrapperInstalled else {
            throw fail(L.t("Steam is already installed.", "Steam est déjà installé."))
        }

        // everything is downloaded before the wrapper exists, so a failed
        // download never leaves a half-built "installed" Steam behind
        try downloadToCache(wrapperDownloads + [winetricksDownload, steamSetupDownload], emit: emit)

        try assembleWrapper(at: wrapperPath, emit: emit)
        let prefix = prefixPath

        // Steam via winetricks (corefonts + known workarounds)
        emit(L.t("Installing Steam (several minutes)…", "Installation de Steam (plusieurs minutes)…"))
        let wtCache = NSHomeDirectory() + "/.cache/winetricks/steam"
        try fm.createDirectory(atPath: wtCache, withIntermediateDirectories: true)
        if !fm.fileExists(atPath: wtCache + "/SteamSetup.exe") {
            try fm.copyItem(atPath: cachePath + "/" + steamSetupDownload.name, toPath: wtCache + "/SteamSetup.exe")
        }
        let wt = sh("/bin/sh", [cachePath + "/" + winetricksDownload.name, "-q", "steam"], env: wineEnv(for: wrapperPath))
        guard wt.code == 0,
              fm.fileExists(atPath: prefix + "/drive_c/Program Files (x86)/Steam/Steam.exe")
        else { throw fail(L.t("Steam installation failed.", "L'installation de Steam a échoué.")) }

        emit(L.t("Configuring…", "Configuration…"))
        guard var plist = readWrapperPlist() else { throw fail("wrapper plist unreadable") }
        plist["CFBundleName"] = "Steam"
        plist["CFBundleIdentifier"] = "com.macplay.steam"
        plist["Program Name and Path"] = "/Program Files (x86)/Steam/Steam.exe"
        plist["Program Flags"] = steamFlags
        setBackend("d3dmetal", in: &plist)
        try writeWrapperPlist(plist)

        emit(L.t("Launching Steam — log in and install your games!",
                 "Lancement de Steam — connecte-toi et installe tes jeux !"))
        GameDisplay.prepareForLaunch()
        sh("/usr/bin/open", [wrapperPath])
    }

    private static func runLauncherStep(wrapper: String, arg: String, doneCheck: () -> Bool,
                                        timeout: TimeInterval = 600) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: wrapper + "/Contents/MacOS/wineskinlauncher")
        p.arguments = [arg]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try p.run()

        let start = Date()
        var confirmed = 0
        while Date().timeIntervalSince(start) < timeout {
            if !p.isRunning { return }
            if doneCheck() {
                confirmed += 1
                if confirmed >= 3 {  // stable across ~6s: the wine work is done
                    p.terminate()
                    return
                }
            } else {
                confirmed = 0
            }
            Thread.sleep(forTimeInterval: 2)
        }
        p.terminate()
        throw fail("wineskinlauncher \(arg): timeout")
    }
}
