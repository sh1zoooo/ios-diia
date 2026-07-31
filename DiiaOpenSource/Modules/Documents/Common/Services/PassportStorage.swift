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
        static let signaturePNG = "fork.passport.signaturePNG" // base64 PNG of the user's hand-drawn signature
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

    /// Each name component uppercased — for the bottomHeading which uses ALL-CAPS
    /// in the original Diia (e.g. "САМУСЕНКО АЛІСА ОЛЕКСАНДРІВНА").
    var fullNameUppercased: String {
        let parts = [surname, firstName, middleName]
            .filter { !$0.isEmpty }
            .map { $0.uppercased() }
        return parts.joined(separator: "\n")
    }

    // MARK: - Signature (hand-drawn PNG, base64)
    /// Stores the user's finger-drawn signature as a base64-encoded PNG string.
    /// `nil` means no signature saved yet.
    var signaturePNGBase64: String? {
        get { defaults.string(forKey: Keys.signaturePNG) }
        set { defaults.set(newValue, forKey: Keys.signaturePNG) }
    }

    var signatureImage: UIImage? {
        guard let b64 = signaturePNGBase64,
              let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    func saveSignature(_ image: UIImage) {
        // Encode as JPEG with white background. Why JPEG not PNG?
        //   DSTableItemVerticalView applies imageByMakingWhiteBackgroundTransparent()
        //   which uses cgImage.copy(maskingColorComponents:). That call requires
        //   an image WITHOUT an alpha channel — PNG-with-alpha makes copy()
        //   return nil and the whole chain silently produces no visible image.
        //   JPEG has no alpha channel, so the masking works as intended:
        //   white pixels → transparent, black strokes → visible.
        //   We composite onto white first in case the input UIImage still
        //   carries transparency from the renderer.
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let composited = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        if let jpg = composited.jpegData(compressionQuality: 0.92) {
            signaturePNGBase64 = jpg.base64EncodedString()
        }
    }

    func clearSignature() {
        defaults.removeObject(forKey: Keys.signaturePNG)
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
