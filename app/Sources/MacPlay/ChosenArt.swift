import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Artwork the player picked for a game or program, keyed like play time (`steam:<appid>`,
/// `app:<name>`). Kept in Application Support: unlike Steam's artwork it can't be fetched again.
final class ChosenArt: ObservableObject {
    static let shared = ChosenArt()
    static let folder = NSHomeDirectory() + "/Library/Application Support/MacPlay/art"

    /// Bumped on every change so artwork views reload.
    @Published private(set) var revision = 0

    private let memory = NSCache<NSString, NSImage>()
    private static let kinds: [GameArt.Kind] = [.cover, .banner]

    func path(_ key: String, _ kind: GameArt.Kind) -> String {
        // percent-encoding keeps any program name a valid, unique file name
        let name = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return Self.folder + "/\(name)-\(kind).jpg"
    }

    func has(_ key: String, _ kind: GameArt.Kind) -> Bool {
        FileManager.default.fileExists(atPath: path(key, kind))
    }

    func image(_ key: String, _ kind: GameArt.Kind) -> NSImage? {
        let file = path(key, kind)
        if let hit = memory.object(forKey: file as NSString) { return hit }
        guard let image = NSImage(contentsOfFile: file) else { return nil }
        memory.setObject(image, forKey: file as NSString)
        return image
    }

    func save(_ image: CGImage, key: String, kind: GameArt.Kind) throws {
        try FileManager.default.createDirectory(atPath: Self.folder, withIntermediateDirectories: true)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw Engine.fail(L.t("Could not save the image.", "Impossible d'enregistrer l'image.", "Gambar tidak bisa disimpan.")) }
        CGImageDestinationAddImage(destination, image,
                                   [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        guard CGImageDestinationFinalize(destination)
        else { throw Engine.fail(L.t("Could not save the image.", "Impossible d'enregistrer l'image.", "Gambar tidak bisa disimpan.")) }
        let file = path(key, kind)
        try (data as Data).write(to: URL(fileURLWithPath: file), options: .atomic)
        changed(file)
    }

    func remove(_ key: String, _ kind: GameArt.Kind) {
        let file = path(key, kind)
        try? FileManager.default.removeItem(atPath: file)
        changed(file)
    }

    func removeAll(for key: String) {
        Self.kinds.forEach { remove(key, $0) }
    }

    /// Follows a program's rename. Goes through a temporary name, so a case-only rename
    /// works on a case-insensitive disk.
    func move(from oldKey: String, to newKey: String) {
        let fm = FileManager.default
        for kind in Self.kinds {
            let old = path(oldKey, kind), new = path(newKey, kind)
            guard old != new, fm.fileExists(atPath: old) else { continue }
            let temp = old + ".moving"
            guard (try? fm.moveItem(atPath: old, toPath: temp)) != nil else { continue }
            try? fm.removeItem(atPath: new)
            if (try? fm.moveItem(atPath: temp, toPath: new)) == nil {
                try? fm.moveItem(atPath: temp, toPath: old)
            }
            changed(old, new)
        }
    }

    private func changed(_ files: String...) {
        files.forEach { memory.removeObject(forKey: $0 as NSString) }
        if Thread.isMainThread {
            revision += 1
        } else {
            DispatchQueue.main.async { self.revision += 1 }
        }
    }
}

/// Turns whatever the player drops, pastes or picks into an image ready to save.
enum ArtIntake {
    static let maxPixels = 1920
    private static let maxDownloadBytes = 30 * 1024 * 1024

    /// Something that may hold an image, in the order it is tried.
    enum Candidate {
        case file(URL)
        case data(Data)
        case link(URL)
    }

    enum Failure: Error {
        case notAnImage
        case downloadFailed

        var message: String {
            switch self {
            case .notAnImage:
                return L.t("That's not an image. Drop or paste a picture, or a link to one.",
                           "Ce n'est pas une image. Dépose ou colle une image, ou un lien vers une image.",
                           "Itu bukan gambar. Tarik atau tempel gambar, atau tautan ke gambar.")
            case .downloadFailed:
                return L.t("Couldn't download that image. Try dragging the image itself, or copy and paste it.",
                           "Impossible de télécharger cette image. Glisse l'image elle-même, ou copie-colle-la.",
                           "Gambar itu tidak bisa diunduh. Coba tarik gambarnya langsung, atau salin lalu tempel.")
            }
        }
    }

    static let dropTypes: [UTType] = [.fileURL, .image, .url, .plainText]

    /// Google Images in the browser; `udm=2` is Google's (undocumented) image results mode.
    static func googleImagesURL(title: String, kind: GameArt.Kind) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        let words = kind == .cover ? "game cover" : "game wallpaper"
        components?.queryItems = [URLQueryItem(name: "udm", value: "2"),
                                  URLQueryItem(name: "q", value: "\(title) \(words)")]
        return components?.url
    }

    static func image(from candidates: [Candidate]) async -> Result<CGImage, Failure> {
        var downloadFailed = false
        for candidate in candidates {
            switch candidate {
            case .file(let url):
                if let data = try? Data(contentsOf: url), let image = prepare(data) { return .success(image) }
            case .data(let data):
                if let image = prepare(data) { return .success(image) }
            case .link(let url):
                if url.scheme == "data" {
                    if let data = decodeDataLink(url.absoluteString), let image = prepare(data) { return .success(image) }
                } else if let data = await download(url) {
                    if let image = prepare(data) { return .success(image) }
                } else {
                    downloadFailed = true
                }
            }
        }
        return .failure(downloadFailed ? .downloadFailed : .notAnImage)
    }

    /// Decodes any format ImageIO reads (JPEG, PNG, WebP, HEIC…) and scales it down.
    /// Re-encoding later keeps only the pixels.
    static func prepare(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    // MARK: sources

    static func candidates(from providers: [NSItemProvider]) async -> [Candidate] {
        var files: [Candidate] = [], images: [Candidate] = [], links: [Candidate] = []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
               let url = await loadURL(provider, .fileURL), url.isFileURL {
                files.append(.file(url))
            }
            if let type = provider.registeredTypeIdentifiers.first(where: { UTType($0)?.conforms(to: .image) == true }),
               let data = await loadData(provider, type) {
                images.append(.data(data))
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
               let url = await loadURL(provider, .url), !url.isFileURL {
                links.append(.link(url))
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                      let text = await loadText(provider), let url = link(in: text) {
                links.append(.link(url))
            }
        }
        return files + images + links
    }

    static func candidatesFromPasteboard() -> [Candidate] {
        let pasteboard = NSPasteboard.general
        var result: [Candidate] = []
        if let files = pasteboard.readObjects(forClasses: [NSURL.self],
                                              options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            result += files.map { .file($0) }
        }
        if let type = pasteboard.types?.first(where: { UTType($0.rawValue)?.conforms(to: .image) == true }),
           let data = pasteboard.data(forType: type) {
            result.append(.data(data))
        }
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            result += urls.filter { !$0.isFileURL }.map { .link($0) }
        }
        if let text = pasteboard.string(forType: .string), let url = link(in: text) {
            result.append(.link(url))
        }
        return result
    }

    // MARK: helpers

    private static func link(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), ["https", "data"].contains(url.scheme?.lowercased()) else { return nil }
        return url
    }

    /// The one image the player pointed at; nothing else is fetched.
    private static func download(_ url: URL) async -> Data? {
        guard url.scheme?.lowercased() == "https" else { return nil }
        let request = URLRequest(url: url, timeoutInterval: 20)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              data.count <= maxDownloadBytes else { return nil }
        return data
    }

    /// `data:image/png;base64,…` links, which is what Google's result thumbnails are.
    static func decodeDataLink(_ link: String) -> Data? {
        guard link.hasPrefix("data:"), let comma = link.firstIndex(of: ",") else { return nil }
        let header = link[link.index(link.startIndex, offsetBy: 5)..<comma]
        let body = String(link[link.index(after: comma)...])
        if header.hasSuffix(";base64") {
            return Data(base64Encoded: body.removingPercentEncoding ?? body, options: .ignoreUnknownCharacters)
        }
        return body.removingPercentEncoding?.data(using: .utf8)
    }

    private static func loadURL(_ provider: NSItemProvider, _ type: UTType) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data {
                    continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                } else if let text = item as? String {
                    continuation.resume(returning: URL(string: text))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func loadData(_ provider: NSItemProvider, _ type: String) async -> Data? {
        await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private static func loadText(_ provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                } else if let data = item as? Data {
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
