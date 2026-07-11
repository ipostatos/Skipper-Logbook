import CoreLocation
import Observation

/// Observable wrapper around `CLLocationManager`. Publishes the latest fix,
/// speed, course and heading, plus the authorization state. It is the single
/// source of live position; higher-level engines (voyage, anchor, MOB) observe it.
@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {

    // Live values (auto-observed by SwiftUI via @Observable)
    private(set) var currentLocation: CLLocation?
    private(set) var speedMps: Double = 0          // clamped ≥ 0
    private(set) var courseDegrees: Double = 0     // course over ground, 0..360
    private(set) var headingDegrees: Double?       // magnetic heading if available
    private(set) var permission: LocationPermission = .notDetermined
    private(set) var isUpdating = false

    /// User toggle: keep tracking when app is backgrounded. Persisted, and only
    /// honoured when `always` authorization + the background capability are
    /// present; enabling it asks for the always-authorization upgrade.
    var allowsBackground = false {
        didSet {
            UserDefaults.standard.set(allowsBackground, forKey: Keys.background)
            if allowsBackground, permission == .whenInUse || permission == .notDetermined {
                requestAlways()
            }
            applyBackgroundSetting()
        }
    }

    /// Safety engines (active anchor watch / MOB) keep background updates on
    /// while they run, independent of the user toggle — an anchor alarm that
    /// stops with the screen is decoration. Honoured only with Always auth.
    var safetyBackgroundOverride = false {
        didSet { applyBackgroundSetting() }
    }

    /// True while the toggle is on but iOS hasn't granted Always authorization —
    /// Settings uses it to explain why background tracking isn't active yet.
    var backgroundUpgradeNeeded: Bool {
        allowsBackground && permission != .always
    }

    /// Fan-out hook for accepted fixes. `FixCoordinator` routes them to the
    /// recorder / anchor / MOB engines — deliberately NOT the view layer, so the
    /// safety chain keeps running even when no SwiftUI scene is being updated
    /// (backgrounded / locked phone).
    var onFix: ((CLLocation) -> Void)?

    private let manager = CLLocationManager()

    private enum Keys {
        static let background = "settings.backgroundTracking"
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .otherNavigation
        manager.distanceFilter = 5
        permission = LocationPermission(manager.authorizationStatus)
        // Direct assignment in init doesn't fire didSet — no permission prompt
        // at launch; the delegate's authorization callback applies the setting.
        allowsBackground = UserDefaults.standard.bool(forKey: Keys.background)
    }

    var currentCoordinate: GeoCoordinate? {
        guard let c = currentLocation?.coordinate else { return nil }
        let geo = GeoCoordinate(c)
        return geo.isValid ? geo : nil
    }

    /// The best available "which way am I pointing" value: true/magnetic heading
    /// when the device provides it, otherwise course over ground.
    var effectiveHeading: Double {
        headingDegrees ?? courseDegrees
    }

    // MARK: Control

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func start() {
        guard permission.isAuthorized else {
            requestWhenInUse()
            return
        }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
        isUpdating = true
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isUpdating = false
    }

    private func applyBackgroundSetting() {
        // Setting this true without the capability + always-auth throws, so guard.
        guard permission == .always else { return }
        let enabled = allowsBackground || safetyBackgroundOverride
        manager.allowsBackgroundLocationUpdates = enabled
        manager.pausesLocationUpdatesAutomatically = !enabled
    }

    // MARK: CLLocationManagerDelegate

    /// A fix is usable when its accuracy is valid and sane (0 < hAcc ≤ 100 m)
    /// and it isn't a stale cached position (the first callback after start can
    /// deliver an old fix). Garbage fixes otherwise pollute the track, the
    /// integrated distance and the anchor-drag decision.
    nonisolated static func isUsable(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy > 0, location.horizontalAccuracy <= 100 else { return false }
        return abs(location.timestamp.timeIntervalSinceNow) <= 15
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.reversed().first(where: Self.isUsable) else { return }
        Task { @MainActor in
            self.currentLocation = latest
            self.speedMps = max(0, latest.speed)
            if latest.course >= 0 {
                self.courseDegrees = latest.course
            }
            self.onFix?(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = value
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.permission = LocationPermission(status)
            if self.permission.isAuthorized, self.isUpdating {
                self.start()
            }
            self.applyBackgroundSetting()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // Non-fatal; keep last known values. Real app would surface transient errors.
    }
}
