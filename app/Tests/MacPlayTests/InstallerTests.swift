import XCTest
@testable import MacPlay

final class InstallerTests: XCTestCase {
    func testMacPathsBecomeZDrivePaths() {
        XCTAssertEqual(WindowsApps.windowsPath("/Users/me/Downloads/My Setup.msi"),
                       "Z:\\Users\\me\\Downloads\\My Setup.msi")
    }

    func testSetupExeRunsDirectly() {
        let exe = URL(fileURLWithPath: "/Users/me/Downloads/TapTapSetup.exe")
        XCTAssertEqual(WindowsApps.installerArguments(for: exe, msiLog: "/tmp/unused.log"),
                       ["/Users/me/Downloads/TapTapSetup.exe"])
    }

    func testPackagesGoThroughWindowsInstallerWithALog() {
        let log = "/Users/me/Library/Caches/macplay/7-Zip-install-msi.log"
        for name in ["7z2603-x64.msi", "SETUP.MSI"] {
            let package = URL(fileURLWithPath: "/Users/me/Downloads/" + name)
            XCTAssertEqual(WindowsApps.installerArguments(for: package, msiLog: log),
                           ["msiexec", "/i", "Z:\\Users\\me\\Downloads\\" + name,
                            "/l*v", "Z:\\Users\\me\\Library\\Caches\\macplay\\7-Zip-install-msi.log"])
        }
    }

    func testPackagesGetANameFromTheirFileName() {
        XCTAssertEqual(WindowsApps.suggestedName(forInstaller: URL(fileURLWithPath: "/d/7z2603-x64.msi")), "7z2603")
        XCTAssertEqual(WindowsApps.suggestedName(forInstaller: URL(fileURLWithPath: "/d/GameSetup.MSI")), "Game")
    }
}
