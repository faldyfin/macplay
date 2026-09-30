import Foundation

/// The compatibility list: MacPlay's curated games plus community data, rebuilt
/// weekly by .github/workflows/update-compatibility.yml. The copy bundled with
/// the app is the fallback; a newer one is downloaded at most once a day.
enum CompatDB {
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/faldyfin/macplay/main/data/compatibility.json")!
    static var cachedPath: String { Engine.cachePath + "/compatibility.json" }
    private static let refreshInterval: TimeInterval = 24 * 3600

    /// The newest readable list: downloaded, bundled, or the curated file alone.
    /// MACPLAY_DATA=<repo>/data is a dev override when running outside an .app bundle.
    static func load() -> GamesFile? {
        let dev = ProcessInfo.processInfo.environment["MACPLAY_DATA"].map { URL(fileURLWithPath: $0) }
        let candidates = [
            URL(fileURLWithPath: cachedPath),
            Bundle.main.resourceURL?.appendingPathComponent("engine/data/compatibility.json"),
            dev?.appendingPathComponent("compatibility.json"),
            Bundle.main.resourceURL?.appendingPathComponent("engine/data/games.json"),
            dev?.appendingPathComponent("games.json"),
        ].compactMap { $0 }

        var best: GamesFile?
        for url in candidates {
            guard let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(GamesFile.self, from: data)
            else { continue }
            // generated_at is ISO 8601 (sorts as text); on a tie the earlier candidate wins
            if best == nil || (file.generated_at ?? "") > (best?.generated_at ?? "") { best = file }
        }
        return best
    }

    /// Downloads the latest list when the cached copy is missing or a day old
    /// (always, with `force`). Returns true when the list got newer.
    static func refresh(force: Bool = false) async -> Bool {
        let fm = FileManager.default
        if !force,
           let modified = (try? fm.attributesOfItem(atPath: cachedPath))?[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) < refreshInterval {
            return false
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            // refuse error pages and truncated or emptied lists
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let file = try? JSONDecoder().decode(GamesFile.self, from: data),
                  file.games.count >= 50
            else { return false }
            let current = load()?.generated_at ?? ""
            try fm.createDirectory(atPath: Engine.cachePath, withIntermediateDirectories: true)
            // written even when unchanged: its date is what spaces the checks a day apart
            try data.write(to: URL(fileURLWithPath: cachedPath), options: .atomic)
            return (file.generated_at ?? "") > current
        } catch {
            return false
        }
    }
}
