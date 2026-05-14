//___FILEHEADER___

import DiiaNetwork
import DiiaCommonTypes
import DiiaCommonServices
import DiiaUIComponents

protocol ___FILEBASENAMEASIDENTIFIER___Protocol {
    func mainScreen(completion: @escaping (Result<DSConstructorModel, NetworkError>) -> Void)
    func statusScreen(applicationId: String, completion: @escaping (Result<DSConstructorModel, NetworkError>) -> Void)
}

final class ___FILEBASENAMEASIDENTIFIER___: ApiClient<___VARIABLE_productName:identifier___API>, ___FILEBASENAMEASIDENTIFIER___Protocol {
    func mainScreen(completion: @escaping (Result<DSConstructorModel, NetworkError>) -> Void) {
        return request(.mainScreen, completion: completion)
    }
    
    func statusScreen(applicationId: String, completion: @escaping (Result<DSConstructorModel, NetworkError>) -> Void) {
        return request(.statusScreen(applicationId: applicationId), completion: completion)
    }
}
