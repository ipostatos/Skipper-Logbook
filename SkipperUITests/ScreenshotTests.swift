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
            "--skip-onboarding",   // land on the tab shell, not the intro
            "--seed-demo",
            "--seed-mob-active",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        // Auto-dismiss the system location-permission dialog if one appears.
        addUIInterruptionMonitor(withDescription: "system-dialog") { alert in
            for label in ["Allow While Using App", "Allow Once", "OK", "Allow"] {
                let button = alert.buttons[label]
                if button.exists { button.tap(); return true }
            }
            return false
        }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)

        // Belt & braces: if onboarding still shows, tap "Get started".
        let getStarted = app.buttons["onboarding.get_started"]
        if getStarted.waitForExistence(timeout: 3) {
            getStarted.tap()
        }
        // Nudge the interruption monitor (it only fires after an interaction).
        app.tap()
    }

    func testCaptureAllScreens() {
        // Fail loudly if we never reached the tab shell (e.g. stuck on
        // onboarding) — otherwise every screenshot would silently be the same
        // screen. This is the one hard assertion in the suite.
        XCTAssertTrue(app.buttons["tab.today"].waitForExistence(timeout: 15),
                      "Tab bar not found — the app did not reach the main shell")

        // 1. Today (launch tab)
        step("01-Today") { tapTab("today") }

        // 2. Map & Route
        step("03-Map") { tapTab("map") }

        // 3. Logbook Timeline
        step("04-Logbook") { tapTab("log") }

        // 4. Audio Log (from the Logbook toolbar mic button). Give the toolbar a
        // moment to lay out after the tab switch, then confirm the sheet opened
        // (its "voice.recent" section / Close button) before capturing.
        step("02-AudioLog") {
            tapTab("log")
            usleep(600_000)
            tapAny("logbook.audiolog")
            // Wait for a control that only exists inside the Audio Log sheet.
            _ = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5)
        }
        dismissSheet()

        // 5. Vessel
        step("05-Vessel") { tapTab("vessel") }

        // 6. Weather (More → Weather tile)
        step("06-Weather") {
            openMoreRoot()
            tapAny("more.tile.weather")
        }

        // 7. Settings (More → gear). Re-tapping the More tab does NOT pop the
        // pushed Weather screen, so we must return to the More root first —
        // otherwise Settings would never be reached and we'd re-capture Weather.
        step("08-Settings") {
            openMoreRoot()
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

    /// Ensures the More tab is showing its menu root (tiles visible), popping any
    /// pushed child first. Re-tapping a tab does not pop its NavigationStack, so
    /// we walk the back button until a tile appears.
    private func openMoreRoot() {
        tapTab("more")
        for _ in 0..<4 {
            if app.buttons["more.tile.weather"].waitForExistence(timeout: 2) { return }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            if back.exists && back.isHittable { back.tap() } else { break }
        }
        _ = app.buttons["more.tile.weather"].waitForExistence(timeout: 3)
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

        // Diagnostic: attach the on-screen element tree so we can tell exactly
        // which screen each shot landed on (helps debug any duplicate captures).
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "\(name)-tree"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
