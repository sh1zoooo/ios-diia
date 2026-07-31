import Foundation
import UIKit

/// FORK: lightweight local storage for the Passport card fields.
/// Same pattern as DriverLicenseStorage — UserDefaults + Documents dir for the photo.
final class PassportStorage {

    static let shared = PassportStorage()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let surname     = "fork.passport.surname"
        static let firstName   = "fork.passport.firstName"
        static let middleName  = "fork.passport.middleName"
        static let birthDate   = "fork.passport.birthDate"
        static let number      = "fork.passport.number"     // series + number, e.g. "ФО 123456"
        static let issuedBy    = "fork.passport.issuedBy"
        static let issuedDate  = "fork.passport.issuedDate"
        static let validUntil  = "fork.passport.validUntil" // for ID-card format
        static let recordNumber = "fork.passport.recordNumber" // номер запису (паспорт ІД)
    }

    private init() {}

    var surname:      String { get { defaults.string(forKey: Keys.surname)      ?? "" } set { defaults.set(newValue, forKey: Keys.surname)      } }
    var firstName:    String { get { defaults.string(forKey: Keys.firstName)    ?? "" } set { defaults.set(newValue, forKey: Keys.firstName)    } }
    var middleName:   String { get { defaults.string(forKey: Keys.middleName)   ?? "" } set { defaults.set(newValue, forKey: Keys.middleName)   } }
    var birthDate:    String { get { defaults.string(forKey: Keys.birthDate)    ?? "" } set { defaults.set(newValue, forKey: Keys.birthDate)    } }
    var number:       String { get { defaults.string(forKey: Keys.number)       ?? "" } set { defaults.set(newValue, forKey: Keys.number)       } }
    var issuedBy:     String { get { defaults.string(forKey: Keys.issuedBy)     ?? "" } set { defaults.set(newValue, forKey: Keys.issuedBy)     } }
    var issuedDate:   String { get { defaults.string(forKey: Keys.issuedDate)   ?? "" } set { defaults.set(newValue, forKey: Keys.issuedDate)   } }
    var validUntil:   String { get { defaults.string(forKey: Keys.validUntil)   ?? "" } set { defaults.set(newValue, forKey: Keys.validUntil)   } }
    var recordNumber: String { get { defaults.string(forKey: Keys.recordNumber) ?? "" } set { defaults.set(newValue, forKey: Keys.recordNumber) } }

    var fullName: String {
        let parts = [surname, firstName, middleName].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    // MARK: - Photo
    private var photoURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("passport_photo.jpg")
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

    var photoBase64: String? {
        guard FileManager.default.fileExists(atPath: photoURL.path),
              let data = try? Data(contentsOf: photoURL) else { return nil }
        return data.base64EncodedString()
    }

    struct Snapshot {
        var surname, firstName, middleName: String
        var birthDate, number, issuedBy, issuedDate: String
        var validUntil, recordNumber: String
    }

    func snapshot() -> Snapshot {
        Snapshot(surname: surname, firstName: firstName, middleName: middleName,
                 birthDate: birthDate, number: number, issuedBy: issuedBy,
                 issuedDate: issuedDate, validUntil: validUntil,
                 recordNumber: recordNumber)
    }

    func apply(_ s: Snapshot) {
        surname      = s.surname
        firstName    = s.firstName
        middleName   = s.middleName
        birthDate    = s.birthDate
        number       = s.number
        issuedBy     = s.issuedBy
        issuedDate   = s.issuedDate
        validUntil   = s.validUntil
        recordNumber = s.recordNumber
    }
}
