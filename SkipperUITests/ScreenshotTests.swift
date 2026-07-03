import XCTest

/// Drives the app to each headline screen and captures a named screenshot.
/// Screenshots are attached to the test result bundle (with
/// `.keepAlways`), so a `.xcresult` produced by CI contains every image even
/// when the run passes. The CI workflow extracts and uploads them as artifacts.
///
/// The app is launched with `--seed-demo` so the screens have realistic content,
/// and (for the MOB case) `--seed-mob-active` so the emergency search screen
/// renders without a live GPS fix.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// One end-to-end pass capturing all eight required screens in order, so a
    /// single CI run yields the full set.
    func testCaptureAllScreens() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--seed-demo",
            "--seed-mob-active",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()

        // Give SwiftUI a moment to settle the first frame.
        _ = app.wait(for: .runningForeground, timeout: 20)

        // 1. Today / Smart Dashboard (launch tab)
        tapTab(app, "today")
        snapshot(app, name: "01-Today")

        // 2. Map & Route
        tapTab(app, "map")
        snapshot(app, name: "03-Map")

        // 3. Logbook Timeline
        tapTab(app, "log")
        snapshot(app, name: "04-Logbook")

        // 4. Audio Log (opened from the Logbook toolbar mic button)
        tap(app, id: "logbook.audiolog")
        snapshot(app, name: "02-AudioLog")
        // Dismiss the sheet before continuing.
        app.swipeDown(velocity: .fast)

        // 5. Vessel
        tapTab(app, "vessel")
        snapshot(app, name: "05-Vessel")

        // 6. Weather (via More → Weather tile)
        tapTab(app, "more")
        tap(app, id: "more.tile.weather")
        snapshot(app, name: "06-Weather")

        // 7. Settings (via More → gear)
        tapTab(app, "more")
        tap(app, id: "more.settings")
        snapshot(app, name: "08-Settings")

        // 8. Emergency MOB — the seeded active incident shows a banner on Today;
        // tapping it opens the full-screen search.
        tapTab(app, "today")
        tap(app, id: "today.mob_active_banner")
        // The MOB search is a full-screen cover; wait for its exit control.
        _ = app.buttons["mob.exit"].waitForExistence(timeout: 5)
        snapshot(app, name: "07-MOB-Emergency")
    }

    // MARK: Helpers

    private func tapTab(_ app: XCUIApplication, _ tab: String) {
        let button = app.buttons["tab.\(tab)"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "tab.\(tab) not found")
        button.tap()
        // Small settle for the navigation stack swap.
        _ = app.wait(for: .runningForeground, timeout: 2)
    }

    private func tap(_ app: XCUIApplication, id: String) {
        let element = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(id) not found")
        element.tap()
    }

    /// Captures the current screen as a kept attachment named `name`.
    private func snapshot(_ app: XCUIApplication, name: String) {
        // Let animations finish so we don't catch a mid-transition frame.
        usleep(700_000)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
