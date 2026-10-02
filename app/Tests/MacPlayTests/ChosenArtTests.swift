import XCTest
@testable import MacPlay

final class ChosenArtTests: XCTestCase {
    private var folder: String!
    private var store: ChosenArt!
    private var image: CGImage!

    override func setUpWithError() throws {
        folder = NSTemporaryDirectory() + "macplay-art-" + UUID().uuidString
        store = ChosenArt(folder: folder)
        image = try XCTUnwrap(ArtIntake.prepare(pngData(width: 60, height: 90)))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: folder)
    }

    func testFileNamesStayDistinctForSimilarNames() {
        XCTAssertNotEqual(store.path("app:A B", .cover), store.path("app:A-B", .cover))
        XCTAssertNotEqual(store.path("app:A", .cover), store.path("app:A", .banner))
    }

    func testSavedArtworkCanBeReadAndRemoved() throws {
        try store.save(image, key: "app:Heartopia", kind: .cover)
        XCTAssertTrue(store.has("app:Heartopia", .cover))
        XCTAssertFalse(store.has("app:Heartopia", .banner))
        XCTAssertNotNil(store.image("app:Heartopia", .cover))

        store.remove("app:Heartopia", .cover)
        XCTAssertFalse(store.has("app:Heartopia", .cover))
        XCTAssertNil(store.image("app:Heartopia", .cover))
    }

    func testRenameMovesBothShapes() throws {
        try store.save(image, key: "app:TapTap", kind: .cover)
        try store.save(image, key: "app:TapTap", kind: .banner)
        store.move(from: "app:TapTap", to: "app:Heartopia")
        XCTAssertFalse(store.has("app:TapTap", .cover))
        XCTAssertTrue(store.has("app:Heartopia", .cover))
        XCTAssertTrue(store.has("app:Heartopia", .banner))
    }

    func testCaseOnlyRenameKeepsTheArtwork() throws {
        try store.save(image, key: "app:heartopia", kind: .cover)
        store.move(from: "app:heartopia", to: "app:Heartopia")
        let files = try FileManager.default.contentsOfDirectory(atPath: folder)
        XCTAssertEqual(files, [URL(fileURLWithPath: store.path("app:Heartopia", .cover)).lastPathComponent])
    }

    func testRemoveAllDeletesEveryShape() throws {
        try store.save(image, key: "app:Old", kind: .cover)
        try store.save(image, key: "app:Old", kind: .banner)
        store.removeAll(for: "app:Old")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder), [])
    }
}
