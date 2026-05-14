//___FILEHEADER___

import Foundation
import DiiaNetwork
import DiiaCommonTypes

enum ___FILEBASENAMEASIDENTIFIER___: CommonService {
    case mainScreen
    case statusScreen(applicationId: String)

    var method: HTTPMethod {
        switch self {
        case .mainScreen,
            .statusScreen:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .mainScreen:
            return "v1/public-service/___VARIABLE_publicServiceCode:bundleIdentifier___/home"
        case .statusScreen(let applicationId):
            return "v1/public-service/___VARIABLE_publicServiceCode:bundleIdentifier___/\(applicationId)"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        default:
            return nil
        }
    }
    
    var analyticsName: String {
        return ""
    }
}
