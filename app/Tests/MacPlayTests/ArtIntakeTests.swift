import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import MacPlay

/// A solid PNG of the given size.
func pngData(width: Int, height: Int) -> Data {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(red: 1, green: 0.4, blue: 0.35, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
}

final class ArtIntakeTests: XCTestCase {
    func testLargeImagesAreScaledToTheLongestSideLimit() throws {
        let image = try XCTUnwrap(ArtIntake.prepare(pngData(width: 2400, height: 1000)))
        XCTAssertEqual(image.width, 1920)
        XCTAssertEqual(image.height, 800)
    }

    func testSmallImagesKeepTheirSize() throws {
        let image = try XCTUnwrap(ArtIntake.prepare(pngData(width: 200, height: 300)))
        XCTAssertEqual(image.width, 200)
        XCTAssertEqual(image.height, 300)
    }

    func testTextIsNotAnImage() {
        XCTAssertNil(ArtIntake.prepare(Data("hello".utf8)))
    }

    func testBase64DataLinksDecode() throws {
        let png = pngData(width: 10, height: 10)
        let decoded = try XCTUnwrap(ArtIntake.decodeDataLink("data:image/png;base64," + png.base64EncodedString()))
        XCTAssertEqual(decoded, png)
        XCTAssertNil(ArtIntake.decodeDataLink("https://example.com/a.png"))
    }

    func testCandidatesAreTriedInOrderUntilOneIsAnImage() async throws {
        let text = FileManager.default.temporaryDirectory.appendingPathComponent("macplay-note.txt")
        try Data("not an image".utf8).write(to: text)
        defer { try? FileManager.default.removeItem(at: text) }

        let result = await ArtIntake.image(from: [.file(text), .data(pngData(width: 30, height: 45))])
        XCTAssertEqual(try result.get().width, 30)
    }

    func testOnlyNonImagesGiveNotAnImage() async {
        let result = await ArtIntake.image(from: [.data(Data("nope".utf8))])
        guard case .failure(.notAnImage) = result else { return XCTFail("expected notAnImage, got \(result)") }
    }

    func testPlainHTTPLinksAreNotDownloaded() async {
        let result = await ArtIntake.image(from: [.link(URL(string: "http://example.com/a.png")!)])
        guard case .failure(.downloadFailed) = result else { return XCTFail("expected downloadFailed, got \(result)") }
    }

    func testGoogleImagesLinkSearchesTheTitle() throws {
        let url = try XCTUnwrap(ArtIntake.googleImagesURL(title: "Heartopia", kind: .cover))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(url.host, "www.google.com")
        XCTAssertEqual(items.first { $0.name == "udm" }?.value, "2")
        XCTAssertEqual(items.first { $0.name == "q" }?.value, "Heartopia game cover")
    }
}
