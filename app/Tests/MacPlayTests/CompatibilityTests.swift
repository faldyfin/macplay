import XCTest
@testable import MacPlay

final class CompatibilityTests: XCTestCase {
    private func entry(source: String?) throws -> GameEntry {
        var json: [String: Any] = ["id": "x", "title": "X", "status": "gold", "backend": ""]
        if let source { json["source"] = source }
        return try JSONDecoder().decode(GameEntry.self, from: JSONSerialization.data(withJSONObject: json))
    }

    func testOnlyMacPlayEntriesCountAsHandTuned() throws {
        XCTAssertTrue(try entry(source: nil).isCurated)
        XCTAssertTrue(try entry(source: "macplay").isCurated)
        XCTAssertFalse(try entry(source: "applegamingwiki").isCurated)
        XCTAssertFalse(try entry(source: "areweanticheatyet").isCurated)
    }

    func testBundledListsDecode() throws {
        let data = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("data")
        let curated = try JSONDecoder().decode(GamesFile.self, from: Data(contentsOf: data.appendingPathComponent("games.json")))
        let imported = try JSONDecoder().decode(GamesFile.self, from: Data(contentsOf: data.appendingPathComponent("compatibility.json")))
        XCTAssertFalse(curated.games.isEmpty)
        XCTAssertTrue(curated.games.allSatisfy(\.isCurated))
        XCTAssertGreaterThan(imported.games.count, curated.games.count)
    }
}
