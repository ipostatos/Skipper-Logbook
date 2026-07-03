import Foundation
import SwiftData

/// A person aboard, with role and contact. Belongs to a `Vessel`.
@Model
final class CrewMember {
    var name: String
    var role: String                 // "Captain" / "Капитан", "Штурман", …
    var phone: String?
    @Attribute(.externalStorage) var avatarData: Data?
    var sortIndex: Int

    var vessel: Vessel?

    init(
        name: String,
        role: String,
        phone: String? = nil,
        avatarData: Data? = nil,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.role = role
        self.phone = phone
        self.avatarData = avatarData
        self.sortIndex = sortIndex
    }

    /// Two-letter monogram fallback when there is no avatar photo.
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }
}
