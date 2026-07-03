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

    /// User toggle: keep tracking when app is backgrounded. Only honoured when
    /// `always` authorization + the background capability are present.
    var allowsBackground = false {
        didSet { applyBackgroundSetting() }
    }

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .otherNavigation
        manager.distanceFilter = 5
        permission = LocationPermission(manager.authorizationStatus)
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
        manager.allowsBackgroundLocationUpdates = allowsBackground
        manager.pausesLocationUpdatesAutomatically = !allowsBackground
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
            self.speedMps = max(0, latest.speed)
            if latest.course >= 0 {
                self.courseDegrees = latest.course
            }
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
