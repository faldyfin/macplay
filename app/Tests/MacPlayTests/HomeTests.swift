import XCTest
@testable import MacPlay

final class HomeTests: XCTestCase {
    private func steam(_ appid: String, _ name: String) -> HomeItem {
        HomeItem(route: .steam(InstalledGame(appid: appid, name: name, installdir: name, sizeBytes: 0)),
                 title: name, appid: Int(appid))
    }

    private func program(_ name: String) -> HomeItem {
        HomeItem(route: .program(WindowsApp(name: name, wrapperPath: "/tmp/\(name).app", category: .game)),
                 title: name, appid: nil)
    }

    func testFeaturedIsTheLastPlayedNotTheMostPlayed() {
        let monday = Date(timeIntervalSince1970: 1_790_000_000), tuesday = monday.addingTimeInterval(86_400)
        let items = [program("Heartopia"), steam("1426210", "It Takes Two")]
        let entries = [PlayTime.appKey("Heartopia"): PlayTime.Entry(seconds: 7200, lastPlayed: monday),
                       PlayTime.steamKey("1426210"): PlayTime.Entry(seconds: 60, lastPlayed: tuesday)]
        XCTAssertEqual(HomeView.lastPlayed(items, entries: entries)?.title, "It Takes Two")
    }

    func testNothingPlayedMeansNoLastPlayed() {
        XCTAssertNil(HomeView.lastPlayed([program("Heartopia")], entries: [:]))
    }
}
