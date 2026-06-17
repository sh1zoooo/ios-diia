
import Foundation
import DiiaNetwork

enum PublicServicesAPI: CommonService {

    case getServices
    case getServiceTemplate(service: String)
    case getPrestartWarning(category: String, service: String?)

    var method: HTTPMethod {
        switch self {
        default:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .getServices:
            return "v3/public-service/catalog"
        case .getServiceTemplate(let service):
            return "v1/public-service/\(service)/portal"
        case .getPrestartWarning:
            return "v1/public-service/prestart-warning"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getPrestartWarning(let category, let service):
            var params = ["categoryCode": category]
            if let service {
                params["serviceCode"] = service
            }
            return params
        default: return nil
        }
    }

    var analyticsName: String {
        switch self {
        case .getServices:
            return Constants.getPublicServices
        case .getServiceTemplate:
            return Constants.getServiceTemplate
        case .getPrestartWarning:
            return Constants.getPrestartWarning
        }
    }
}

private extension PublicServicesAPI {
    enum Constants {
        static let getPublicServices = "getPublicServices"
        static let getServiceTemplate = "getServiceTemplate"
        static let getPrestartWarning = "getPrestartWarning"
    }
}
