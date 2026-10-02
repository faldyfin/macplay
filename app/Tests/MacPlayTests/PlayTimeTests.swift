import XCTest
@testable import MacPlay

final class PlayTimeTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 1_790_000_000)

    func testRenameMovesTheTime() throws {
        let entries = ["app:TapTap": PlayTime.Entry(seconds: 120, lastPlayed: day)]
        let moved = try XCTUnwrap(PlayTime.renamed(entries, from: "app:TapTap", to: "app:Heartopia"))
        XCTAssertNil(moved["app:TapTap"])
        XCTAssertEqual(moved["app:Heartopia"]?.seconds, 120)
    }

    func testRenameOntoAnOldNameAddsTheTimes() throws {
        let later = day.addingTimeInterval(3600)
        let entries = ["app:A": PlayTime.Entry(seconds: 60, lastPlayed: later),
                       "app:B": PlayTime.Entry(seconds: 30, lastPlayed: day)]
        let merged = try XCTUnwrap(PlayTime.renamed(entries, from: "app:A", to: "app:B"))
        XCTAssertEqual(merged["app:B"]?.seconds, 90)
        XCTAssertEqual(merged["app:B"]?.lastPlayed, later)
    }

    func testRenameWithoutHistoryChangesNothing() {
        XCTAssertNil(PlayTime.renamed([:], from: "app:A", to: "app:B"))
        XCTAssertNil(PlayTime.renamed(["app:A": PlayTime.Entry(seconds: 1, lastPlayed: day)], from: "app:A", to: "app:A"))
    }

    func testPlayTimeText() {
        let saved = UserDefaults.standard.string(forKey: "lang")
        defer { UserDefaults.standard.set(saved, forKey: "lang") }

        UserDefaults.standard.set("en", forKey: "lang")
        XCTAssertEqual(playTimeText(45 * 60), "45 min")
        XCTAssertEqual(playTimeText(200 * 60), "3 h 20 min")
        UserDefaults.standard.set("id", forKey: "lang")
        XCTAssertEqual(playTimeText(200 * 60), "3 jam 20 menit")
    }
}
