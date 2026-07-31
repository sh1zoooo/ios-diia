import Foundation
import UIKit

/// FORK: lightweight local storage for the driver-license fields the user fills in manually.
/// Lives in `UserDefaults` directly (like `ProfileStorage`) so it is NOT affected by
/// `StoreHelper.clearAllData()`, which otherwise wipes the Documents-tab card on every launch.
/// `DriverLicenseSeeder` reads this storage and rebuilds the displayed card from it.
final class DriverLicenseStorage {

    static let shared = DriverLicenseStorage()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let fullName    = "fork.driverLicense.fullName"
        static let birthDate   = "fork.driverLicense.birthDate"
        static let category    = "fork.driverLicense.category"
        static let number      = "fork.driverLicense.number"
        static let issuedBy    = "fork.driverLicense.issuedBy"
        static let validUntil  = "fork.driverLicense.validUntil"
    }

    private init() {}

    var fullName:   String { get { defaults.string(forKey: Keys.fullName)   ?? "" } set { defaults.set(newValue, forKey: Keys.fullName)   } }
    var birthDate:  String { get { defaults.string(forKey: Keys.birthDate)  ?? "" } set { defaults.set(newValue, forKey: Keys.birthDate)  } }
    var category:   String { get { defaults.string(forKey: Keys.category)   ?? "" } set { defaults.set(newValue, forKey: Keys.category)   } }
    var number:     String { get { defaults.string(forKey: Keys.number)     ?? "" } set { defaults.set(newValue, forKey: Keys.number)     } }
    var issuedBy:   String { get { defaults.string(forKey: Keys.issuedBy)   ?? "" } set { defaults.set(newValue, forKey: Keys.issuedBy)   } }
    var validUntil: String { get { defaults.string(forKey: Keys.validUntil) ?? "" } set { defaults.set(newValue, forKey: Keys.validUntil) } }

    // MARK: - Photo (same pattern as ProfileStorage's avatar)
    private var photoURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("driver_license_photo.jpg")
    }

    var photo: UIImage? {
        guard FileManager.default.fileExists(atPath: photoURL.path) else { return nil }
        return UIImage(contentsOfFile: photoURL.path)
    }

    func savePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: photoURL, options: .atomic)
    }

    func clearPhoto() {
        try? FileManager.default.removeItem(at: photoURL)
    }

    /// Base64 string (no data-URI prefix) ready to drop into `DSDocumentContent.image`.
    var photoBase64: String? {
        guard FileManager.default.fileExists(atPath: photoURL.path),
              let data = try? Data(contentsOf: photoURL) else { return nil }
        return data.base64EncodedString()
    }

    struct Snapshot {
        var fullName: String
        var birthDate: String
        var category: String
        var number: String
        var issuedBy: String
        var validUntil: String
    }

    func snapshot() -> Snapshot {
        Snapshot(fullName: fullName, birthDate: birthDate, category: category,
                 number: number, issuedBy: issuedBy, validUntil: validUntil)
    }

    func apply(_ snapshot: Snapshot) {
        fullName = snapshot.fullName
        birthDate = snapshot.birthDate
        category = snapshot.category
        number = snapshot.number
        issuedBy = snapshot.issuedBy
        validUntil = snapshot.validUntil
    }
}
