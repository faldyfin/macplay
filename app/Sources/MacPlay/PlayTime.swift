import Foundation

/// Play time per Steam game and per program, counted while MacPlay is open and kept
/// only in this Mac's preferences. One process listing every 30 seconds.
/// A game started inside a launcher (Heartopia in TapTap) counts for the launcher.
final class PlayTime: ObservableObject {
    static let shared = PlayTime()
    static let tick: TimeInterval = 30
    private static let storeKey = "playTime"

    struct Entry: Codable {
        var seconds: Double
        var lastPlayed: Date
    }

    @Published private(set) var entries: [String: Entry] = [:]
    /// Keys running at the last check.
    @Published private(set) var running: [String] = []

    private var timer: Timer?

    private init() {
        entries = Self.load()
    }

    static func steamKey(_ appid: String) -> String { "steam:" + appid }
    static func appKey(_ name: String) -> String { "app:" + name }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Self.tick, repeats: true) { [weak self] _ in
            self?.sample(counting: true)
        }
        sample(counting: false)  // show what runs right away, without adding time
    }

    var totalSeconds: Double { entries.values.reduce(0) { $0 + $1.seconds } }

    var mostPlayed: [(key: String, entry: Entry)] {
        entries.sorted { $0.value.seconds > $1.value.seconds }.map { (key: $0.key, entry: $0.value) }
    }

    private func sample(counting: Bool) {
        DispatchQueue.global(qos: .utility).async {
            let found = Self.runningKeys()
            DispatchQueue.main.async {
                self.running = found
                guard counting, !found.isEmpty else { return }
                let now = Date()
                for key in found {
                    var entry = self.entries[key] ?? Entry(seconds: 0, lastPlayed: now)
                    entry.seconds += Self.tick
                    entry.lastPlayed = now
                    self.entries[key] = entry
                }
                Self.save(self.entries)
            }
        }
    }

    /// Steam games by their install folder in a process path; programs while their
    /// wrapper has a Wine session.
    static func runningKeys() -> [String] {
        let processes = Engine.sh("/bin/ps", ["-axww", "-o", "command"]).out
        var keys: [String] = []
        for game in SteamLibrary.installedGames()
        where processes.range(of: game.processPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            keys.append(steamKey(game.appid))
        }
        for app in WindowsApps.list()
        where processes.range(of: NSRegularExpression.escapedPattern(for: app.wrapperPath) + ".*wineserver",
                              options: .regularExpression) != nil {
            keys.append(appKey(app.name))
        }
        return keys
    }

    private static func load() -> [String: Entry] {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func save(_ entries: [String: Entry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

/// "45 min", "3 h 20 min", in the UI language.
func playTimeText(_ seconds: Double) -> String {
    let minutes = Int(seconds / 60)
    if minutes < 60 { return L.t("\(minutes) min", "\(minutes) min", "\(minutes) menit") }
    let hours = minutes / 60, rest = minutes % 60
    return L.t("\(hours) h \(rest) min", "\(hours) h \(rest) min", "\(hours) jam \(rest) menit")
}
