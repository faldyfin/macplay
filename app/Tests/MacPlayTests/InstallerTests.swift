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

    func testWindowedProgramsBeatConsoleTools() {
        let installed = ["/Program Files/7-Zip/7z.exe", "/Program Files/7-Zip/7zFM.exe", "/Program Files/7-Zip/7zG.exe"]
        XCTAssertEqual(WindowsApps.pickMainProgram(installed, appName: "7z2603",
                                                   consolePrograms: ["/Program Files/7-Zip/7z.exe"]),
                       "/Program Files/7-Zip/7zFM.exe")
    }

    func testANameMatchStillComesFirst() {
        let installed = ["/Program Files/TapTapGlobal/Helper.exe", "/Program Files/TapTapGlobal/TapTapGlobal.exe"]
        XCTAssertEqual(WindowsApps.pickMainProgram(installed, appName: "TapTap",
                                                   consolePrograms: ["/Program Files/TapTapGlobal/TapTapGlobal.exe"]),
                       "/Program Files/TapTapGlobal/TapTapGlobal.exe")
    }

    /// The smallest file with a PE header: MZ, the PE offset, the signature, an empty COFF
    /// header and an optional header carrying only its magic and the subsystem.
    private func fakeExecutable(subsystem: UInt16) throws -> String {
        var bytes = [UInt8](repeating: 0, count: 0x40 + 24 + 70)
        bytes[0] = 0x4D
        bytes[1] = 0x5A
        bytes[0x3C] = 0x40
        bytes[0x40...0x43] = [0x50, 0x45, 0, 0]
        let optional = 0x40 + 24
        bytes[optional] = 0x0B
        bytes[optional + 1] = 0x02
        bytes[optional + 68] = UInt8(subsystem & 0xFF)
        bytes[optional + 69] = UInt8(subsystem >> 8)
        let path = NSTemporaryDirectory() + "macplay-\(UUID().uuidString).exe"
        try Data(bytes).write(to: URL(fileURLWithPath: path))
        return path
    }

    func testConsoleProgramsAreToldApartByTheirHeader() throws {
        let console = try fakeExecutable(subsystem: 3)
        let windowed = try fakeExecutable(subsystem: 2)
        defer { [console, windowed].forEach { try? FileManager.default.removeItem(atPath: $0) } }
        XCTAssertTrue(WindowsApps.isConsoleProgram(atPath: console))
        XCTAssertFalse(WindowsApps.isConsoleProgram(atPath: windowed))
        XCTAssertFalse(WindowsApps.isConsoleProgram(atPath: "/nonexistent/program.exe"))
    }

    func testPackagesGetANameFromTheirFileName() {
        XCTAssertEqual(WindowsApps.suggestedName(forInstaller: URL(fileURLWithPath: "/d/7z2603-x64.msi")), "7z2603")
        XCTAssertEqual(WindowsApps.suggestedName(forInstaller: URL(fileURLWithPath: "/d/GameSetup.MSI")), "Game")
    }
}
