import CoreLocation
import SwiftUI

/// UI-friendly view of the CoreLocation authorization state, with a localized
/// rationale for the onboarding / settings screens.
enum LocationPermission: Equatable {
    case notDetermined
    case whenInUse
    case always
    case denied
    case restricted

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:          self = .notDetermined
        case .authorizedWhenInUse:    self = .whenInUse
        case .authorizedAlways:       self = .always
        case .denied:                 self = .denied
        case .restricted:             self = .restricted
        @unknown default:             self = .denied
        }
    }

    /// Whether we currently have enough permission to read location at all.
    var isAuthorized: Bool { self == .whenInUse || self == .always }

    var titleKey: LocalizedStringKey {
        switch self {
        case .notDetermined: return "permission.location.not_determined"
        case .whenInUse:     return "permission.location.when_in_use"
        case .always:        return "permission.location.always"
        case .denied:        return "permission.location.denied"
        case .restricted:    return "permission.location.restricted"
        }
    }
}
