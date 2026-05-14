//___FILEHEADER___

import UIKit
import DiiaNetwork
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import DiiaCommonServices

protocol ___VARIABLE_productName:identifier___Action: BasePresenter {
    func actionTapped()
}

final class ___FILEBASENAMEASIDENTIFIER___: ___VARIABLE_productName:identifier___Action {
    // MARK: - Properties
    unowned var view: ___VARIABLE_productName:identifier___View
    
    private let flowCoordinator: FlowCoordinatorProtocol
    //    private let apiClient: APIClientProtocol

    // MARK: - Init
    init(view: ___VARIABLE_productName:identifier___View,
         flowCoordinator: FlowCoordinatorProtocol) {
        self.view = view
        self.flowCoordinator = flowCoordinator
        //        self.apiClient = APIClient()
    }
    
    // MARK: - Public Methods
    func configureView() {
        fetchScreen()
    }

    func actionTapped() {
        // ...
    }

    // MARK: - Private Methods
    // MARK: - API Methods
    private func fetchScreen() {
//        view.setLoadingState(.loading)
//
//        apiClient.mainScreen { [weak self] result in
//            self?.view.setLoadingState(.ready)
//            switch result {
//            case let .success(response):
//                self?.processResponse(response)
//            case let.failure(error):
//                self?.handleError(error: error) {
//                    self?.fetchScreen()
//                }
//            }
//        }
    }

//    private func processResponse(_ response: Model) {
//        view.configure(model: response)
//    }

    // MARK: - Handlers
    private func handleError(error: NetworkError, retryAction: @escaping Callback) {
        GeneralErrorsHandler.process(
            error: .init(networkError: error),
            with: retryAction,
            didRetry: false,
            in: view
        )
    }
}
