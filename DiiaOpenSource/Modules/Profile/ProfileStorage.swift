import UIKit

/// FORK: lightweight local profile storage.
/// Persists name / photo / extra fields directly in `UserDefaults`
/// (text fields) and the app's `Documents` directory (avatar JPEG).
/// Nothing here touches the network or Diia's existing StoreHelper.
final class ProfileStorage {

    static let shared = ProfileStorage()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let firstName  = "fork.profile.firstName"
        static let lastName   = "fork.profile.lastName"
        static let middleName = "fork.profile.middleName"
        static let birthDate  = "fork.profile.birthDate"
        static let city       = "fork.profile.city"
        static let phone      = "fork.profile.phone"
        static let email      = "fork.profile.email"
        static let about      = "fork.profile.about"
    }

    private init() {}

    // MARK: - Plain string fields
    var firstName:  String { get { defaults.string(forKey: Keys.firstName)  ?? "" } set { defaults.set(newValue, forKey: Keys.firstName)  } }
    var lastName:   String { get { defaults.string(forKey: Keys.lastName)   ?? "" } set { defaults.set(newValue, forKey: Keys.lastName)   } }
    var middleName: String { get { defaults.string(forKey: Keys.middleName) ?? "" } set { defaults.set(newValue, forKey: Keys.middleName) } }
    var city:       String { get { defaults.string(forKey: Keys.city)       ?? "" } set { defaults.set(newValue, forKey: Keys.city)       } }
    var phone:      String { get { defaults.string(forKey: Keys.phone)      ?? "" } set { defaults.set(newValue, forKey: Keys.phone)      } }
    var email:      String { get { defaults.string(forKey: Keys.email)      ?? "" } set { defaults.set(newValue, forKey: Keys.email)      } }
    var about:      String { get { defaults.string(forKey: Keys.about)      ?? "" } set { defaults.set(newValue, forKey: Keys.about)      } }

    // MARK: - Birth date
    var birthDate: Date? {
        get { defaults.object(forKey: Keys.birthDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.birthDate) }
    }

    // MARK: - Photo
    private var photoURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_avatar.jpg")
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

    /// Snapshot of all fields used by the Profile screen.
    struct Snapshot {
        var firstName:  String
        var lastName:   String
        var middleName: String
        var birthDate:  Date?
        var city:       String
        var phone:      String
        var email:      String
        var about:      String
        var photo:      UIImage?
    }

    func snapshot() -> Snapshot {
        Snapshot(
            firstName:  firstName,
            lastName:   lastName,
            middleName: middleName,
            birthDate:  birthDate,
            city:       city,
            phone:      phone,
            email:      email,
            about:      about,
            photo:      photo
        )
    }

    func apply(_ snapshot: Snapshot) {
        firstName  = snapshot.firstName
        lastName   = snapshot.lastName
        middleName = snapshot.middleName
        birthDate  = snapshot.birthDate
        city       = snapshot.city
        phone      = snapshot.phone
        email      = snapshot.email
        about      = snapshot.about
    }
}
