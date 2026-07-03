import XCTest

/// Drives the app to each headline screen and captures a named screenshot.
/// Screenshots are attached to the test result bundle with `.keepAlways`, so a
/// `.xcresult` produced by CI contains every image even when the run passes.
///
/// The test is deliberately fault-tolerant: if one screen can't be reached, it
/// logs the miss and moves on rather than failing the whole run — a partial set
/// of screenshots is far more useful than none, and the run stays green so the
/// simulator-build artifact is still produced.
///
/// Launch flags: `--seed-demo` gives the screens realistic content, and
/// `--seed-mob-active` makes the emergency MOB search render without a live fix.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = [
            "--seed-demo",
            "--seed-mob-active",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
    }

    func testCaptureAllScreens() {
        // 1. Today (launch tab)
        step("01-Today") { tapTab("today") }

        // 2. Map & Route
        step("03-Map") { tapTab("map") }

        // 3. Logbook Timeline
        step("04-Logbook") { tapTab("log") }

        // 4. Audio Log (from the Logbook toolbar mic button)
        step("02-AudioLog") {
            tapTab("log")
            tapAny("logbook.audiolog")
        }
        dismissSheet()

        // 5. Vessel
        step("05-Vessel") { tapTab("vessel") }

        // 6. Weather (More → Weather tile)
        step("06-Weather") {
            tapTab("more")
            tapAny("more.tile.weather")
        }

        // 7. Settings (More → gear)
        step("08-Settings") {
            tapTab("more")
            tapAny("more.settings")
        }

        // 8. Emergency MOB — seeded active incident shows a banner on Today.
        step("07-MOB-Emergency") {
            tapTab("today")
            tapAny("today.mob_active_banner")
            _ = app.buttons["mob.exit"].waitForExistence(timeout: 6)
        }
    }

    // MARK: Screen step wrapper — captures even if navigation partly fails

    private func step(_ name: String, _ navigate: () -> Void) {
        navigate()
        usleep(800_000)                 // let transitions/animations finish
        snapshot(name)
    }

    // MARK: Navigation helpers (non-fatal)

    private func tapTab(_ tab: String) {
        let button = app.buttons["tab.\(tab)"]
        if button.waitForExistence(timeout: 12) {
            button.tap()
            _ = app.wait(for: .runningForeground, timeout: 2)
        } else {
            XCTContext.runActivity(named: "tab.\(tab) not found") { _ in }
        }
    }

    /// Taps an element with the given identifier, trying buttons first, then any
    /// element type (toolbar items, custom controls, images).
    private func tapAny(_ id: String) {
        let candidates = [
            app.buttons[id],
            app.otherElements[id],
            app.images[id],
            app.descendants(matching: .any).matching(identifier: id).firstMatch
        ]
        for element in candidates where element.waitForExistence(timeout: 3) {
            if element.isHittable {
                element.tap()
            } else {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            return
        }
        XCTContext.runActivity(named: "\(id) not found") { _ in }
    }

    private func dismissSheet() {
        // Swipe the sheet down; harmless if there's no sheet.
        app.swipeDown(velocity: .fast)
        usleep(400_000)
    }

    // MARK: Screenshot

    private func snapshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
