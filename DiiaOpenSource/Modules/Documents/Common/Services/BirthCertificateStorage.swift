import Foundation
import UIKit

/// FORK: storage for the "Актовий запис про народження" card fields.
final class BirthCertificateStorage {

    static let shared = BirthCertificateStorage()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let surname      = "fork.birthCert.surname"
        static let firstName    = "fork.birthCert.firstName"
        static let middleName   = "fork.birthCert.middleName"
        static let birthDate    = "fork.birthCert.birthDate"
        static let birthPlace   = "fork.birthCert.birthPlace"
        static let recordNumber = "fork.birthCert.recordNumber"   // номер актового запису
        static let issuedBy     = "fork.birthCert.issuedBy"        // орган ЗАГС
        static let issuedDate   = "fork.birthCert.issuedDate"      // дата реєстрації
    }

    private init() {}

    var surname:      String { get { defaults.string(forKey: Keys.surname)      ?? "" } set { defaults.set(newValue, forKey: Keys.surname)      } }
    var firstName:    String { get { defaults.string(forKey: Keys.firstName)    ?? "" } set { defaults.set(newValue, forKey: Keys.firstName)    } }
    var middleName:   String { get { defaults.string(forKey: Keys.middleName)   ?? "" } set { defaults.set(newValue, forKey: Keys.middleName)   } }
    var birthDate:    String { get { defaults.string(forKey: Keys.birthDate)    ?? "" } set { defaults.set(newValue, forKey: Keys.birthDate)    } }
    var birthPlace:   String { get { defaults.string(forKey: Keys.birthPlace)   ?? "" } set { defaults.set(newValue, forKey: Keys.birthPlace)   } }
    var recordNumber: String { get { defaults.string(forKey: Keys.recordNumber) ?? "" } set { defaults.set(newValue, forKey: Keys.recordNumber) } }
    var issuedBy:     String { get { defaults.string(forKey: Keys.issuedBy)     ?? "" } set { defaults.set(newValue, forKey: Keys.issuedBy)     } }
    var issuedDate:   String { get { defaults.string(forKey: Keys.issuedDate)   ?? "" } set { defaults.set(newValue, forKey: Keys.issuedDate)   } }

    var fullName: String {
        let parts = [surname, firstName, middleName].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    struct Snapshot {
        var surname, firstName, middleName: String
        var birthDate, birthPlace, recordNumber: String
        var issuedBy, issuedDate: String
    }

    func snapshot() -> Snapshot {
        Snapshot(surname: surname, firstName: firstName, middleName: middleName,
                 birthDate: birthDate, birthPlace: birthPlace,
                 recordNumber: recordNumber, issuedBy: issuedBy,
                 issuedDate: issuedDate)
    }

    func apply(_ s: Snapshot) {
        surname      = s.surname
        firstName    = s.firstName
        middleName   = s.middleName
        birthDate    = s.birthDate
        birthPlace   = s.birthPlace
        recordNumber = s.recordNumber
        issuedBy     = s.issuedBy
        issuedDate   = s.issuedDate
    }
}
