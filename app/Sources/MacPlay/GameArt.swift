import AppKit
import SwiftUI

/// Official game artwork from Steam's public image server, looked up by Steam app id
/// and kept in ~/Library/Caches/macplay/art so each image is downloaded once.
enum GameArt {
    enum Kind {
        case cover   // portrait card
        case banner  // wide hero

        /// Tried in order; some games only have part of the set (Heartopia has only the hero).
        var files: [String] {
            switch self {
            case .cover: return ["library_600x900.jpg", "library_hero.jpg", "header.jpg"]
            case .banner: return ["library_hero.jpg", "header.jpg"]
            }
        }
    }

    static let base = "https://cdn.akamai.steamstatic.com/steam/apps/"
    static var cacheDir: String { Engine.cachePath + "/art" }
    /// A file Steam did not have is asked for again after this long (new games gain artwork).
    private static let missingRetry: TimeInterval = 7 * 24 * 3600
    private static let memory = NSCache<NSString, NSImage>()

    static func image(appid: Int, kind: Kind) async -> NSImage? {
        let key = "\(appid)-\(kind)" as NSString
        if let hit = memory.object(forKey: key) { return hit }
        let fm = FileManager.default
        try? fm.createDirectory(atPath: cacheDir, withIntermediateDirectories: true)

        for file in kind.files {
            let path = cacheDir + "/\(appid)-\(file)"
            if let image = NSImage(contentsOfFile: path) {
                memory.setObject(image, forKey: key)
                return image
            }
            let marker = path + ".missing"
            if let date = (try? fm.attributesOfItem(atPath: marker))?[.modificationDate] as? Date,
               Date().timeIntervalSince(date) < missingRetry {
                continue
            }
            guard let url = URL(string: base + "\(appid)/" + file) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 404 || status == 403 {
                    fm.createFile(atPath: marker, contents: nil)
                    continue
                }
                guard status == 200, let image = NSImage(data: data) else { continue }
                try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
                try? fm.removeItem(atPath: marker)
                memory.setObject(image, forKey: key)
                return image
            } catch {
                return nil  // offline: placeholder for now, asked again next time
            }
        }
        return nil
    }
}

/// Artwork that fills and crops its frame, with a placeholder until (or unless) it arrives.
struct ArtImage: View {
    let appid: Int?
    let kind: GameArt.Kind
    let title: String

    @State private var image: NSImage?

    var body: some View {
        // the image is an overlay so its fill size never widens the layout
        ArtPlaceholder(title: title)
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                }
            }
            .clipped()
        .task(id: appid) {
            guard let appid else { return }
            let loaded = await GameArt.image(appid: appid, kind: kind)
            withAnimation(.easeOut(duration: 0.25)) { image = loaded }
        }
    }
}
