import UIKit
import DiiaDocumentsCommonTypes

enum DocType: String, Codable, CaseIterable {
    case driverLicense = "driver-license"
    case taxpayerСard = "taxpayer-card"
    // FORK: extra local-only document types.
    case passport = "passport"
    case birthCertificate = "birth-certificate"

    init?(rawValue: String) {
        switch rawValue {
        case "driver-license", "driverLicense":
            self = .driverLicense
        case "taxpayer-card", "taxpayerСard":
            self = .taxpayerСard
        case "passport":
            self = .passport
        case "birth-certificate":
            self = .birthCertificate
        default:
            return nil
        }
    }
    
    var name: String {
        switch self {
        case .driverLicense:
            return R.Strings.driver_document_name.localized()
        case .taxpayerСard:
            return ""
        case .passport:
            return "Паспорт громадянина України"
        case .birthCertificate:
            return "Актовий запис про народження"
        }
    }

    var stackName: String {
        return name
    }

    static var allCardTypes: [DocType] {
        return DocType.allCases
    }

    var faqCategoryId: String {
        switch self {
        case .driverLicense: return "driverLicense"
        case .taxpayerСard: return ""
        case .passport: return "passport"
        case .birthCertificate: return "birthCertificate"
        }
    }

    func storingKey() -> StoringKey? {
        switch self {
        case .driverLicense:
            return .driverLicense
        case .taxpayerСard:
            return nil
        case .passport:
            return .passport
        case .birthCertificate:
            return .birthCertificate
        }
    }
}

extension DocType: DocumentAttributesProtocol {
    var docCode: DocTypeCode { return self.rawValue }

    func warningModel() -> WarningModel? {
        return nil
    }

    var stackIconAppearance: DocumentStackIconAppearance {
        return .black
    }

    var isStaticDoc: Bool {
        return false
    }

    func isDocCodeSameAs(otherDocCode: DocTypeCode) -> Bool {
        DocType(rawValue: docCode) == DocType(rawValue: otherDocCode)
    }
}
