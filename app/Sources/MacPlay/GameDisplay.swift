import AppKit

/// Which screen games open on. Wine's Mac driver makes the macOS main display
/// the Windows primary monitor (the one fullscreen games use, and the only one
/// whose resolution Wine can switch), so the chosen screen is made the main
/// display before a launch. That moves the menu bar and Dock there as well.
/// The change is app-scoped: macOS reverts it if MacPlay quits, and MacPlay
/// reverts it once no wrapper is running any more.
enum GameDisplay {
    struct Screen: Identifiable {
        let id: CGDirectDisplayID
        let name: String
        let isBuiltin: Bool
        let isMain: Bool
        /// Stable across reconnects, unlike the display id.
        var key: String { isBuiltin ? "builtin" : name }
    }

    /// UserDefaults key holding the chosen screen's `key`; empty = leave the main display alone.
    static let preferenceKey = "gameDisplay"

    private static let lock = NSLock()
    private static var originalOrigins: [CGDirectDisplayID: CGPoint]?
    private static var watcher: Task<Void, Never>?

    static func screens() -> [Screen] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return ids.compactMap { id in
            guard CGDisplayIsInMirrorSet(id) == 0 || CGDisplayIsMain(id) != 0 else { return nil }
            let name = NSScreen.screens.first {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id
            }?.localizedName ?? "Display \(id)"
            return Screen(id: id, name: name, isBuiltin: CGDisplayIsBuiltin(id) != 0, isMain: CGDisplayIsMain(id) != 0)
        }
    }

    /// True while MacPlay has moved the main display.
    static var isRearranged: Bool {
        lock.lock(); defer { lock.unlock() }
        return originalOrigins != nil
    }

    /// Before launching a wrapper: make the chosen screen the main display, if it
    /// is connected and isn't already. Wine reads the arrangement when it starts.
    static func prepareForLaunch() {
        guard let key = UserDefaults.standard.string(forKey: preferenceKey), !key.isEmpty else { return }
        let all = screens()
        guard all.count > 1, let target = all.first(where: { $0.key == key }), !target.isMain else { return }

        lock.lock()
        let saved = originalOrigins ?? Dictionary(uniqueKeysWithValues: all.map { ($0.id, CGDisplayBounds($0.id).origin) })
        lock.unlock()

        let shift = CGDisplayBounds(target.id).origin
        if apply(Dictionary(uniqueKeysWithValues: all.map {
            let o = CGDisplayBounds($0.id).origin
            return ($0.id, CGPoint(x: o.x - shift.x, y: o.y - shift.y))
        })) {
            lock.lock(); originalOrigins = saved; lock.unlock()
            watchUntilWrappersClose()
        }
    }

    /// Put the screens back where they were.
    static func restore() {
        lock.lock()
        let saved = originalOrigins
        originalOrigins = nil
        watcher?.cancel()
        watcher = nil
        lock.unlock()
        // only the displays still connected can be placed
        if let saved { _ = apply(saved.filter { id, _ in screens().contains { $0.id == id } }) }
    }

    private static func apply(_ origins: [CGDirectDisplayID: CGPoint]) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
        for (id, origin) in origins {
            CGConfigureDisplayOrigin(config, id, Int32(origin.x), Int32(origin.y))
        }
        // app-scoped: reverts by itself when MacPlay quits
        guard CGCompleteDisplayConfiguration(config, .forAppOnly) == .success else {
            CGCancelDisplayConfiguration(config)
            return false
        }
        return true
    }

    /// Restore once no Sikarugir wrapper (Steam or a Windows app) has a Wine session left.
    private static func watchUntilWrappersClose() {
        lock.lock(); defer { lock.unlock() }
        guard watcher == nil else { return }
        watcher = Task.detached(priority: .utility) {
            try? await Task.sleep(nanoseconds: 30_000_000_000)  // let the wrapper start first
            var idleChecks = 0
            while !Task.isCancelled {
                let alive = Engine.processAlive(NSHomeDirectory() + "/Applications/Sikarugir/.*wineserver")
                idleChecks = alive ? 0 : idleChecks + 1
                if idleChecks >= 2 {
                    restore()
                    return
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
}
