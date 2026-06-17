
import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaCommonTypes
import DiiaUIComponents

protocol PublicServicesAPIClientProtocol {
    func getPublicServices() -> Signal<PublicServiceResponse, NetworkError>
    func getServiceTemplate(for service: String) -> Signal<AlertTemplateResponse, NetworkError>
    func getPrestartWarning(category: String, service: String?, callback: @escaping (Result<AlertTemplateResponse, NetworkError>) -> Void)
}

final class PublicServicesAPIClient: ApiClient<PublicServicesAPI>, PublicServicesAPIClientProtocol {

    func getPublicServices() -> Signal<PublicServiceResponse, NetworkError> {
        return request(.getServices)
    }
    
    func getServiceTemplate(for service: String) -> Signal<AlertTemplateResponse, NetworkError> {
        return request(.getServiceTemplate(service: service))
    }
    
    func getPrestartWarning(category: String, service: String?, callback: @escaping (Result<AlertTemplateResponse, NetworkError>) -> Void) {
        request(.getPrestartWarning(category: category, service: service), completion: callback)
    }
}

