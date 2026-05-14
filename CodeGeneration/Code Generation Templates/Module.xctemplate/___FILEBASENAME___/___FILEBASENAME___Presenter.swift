//___FILEHEADER___

import UIKit
import DiiaNetwork
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import DiiaCommonServices

final class ___FILEBASENAMEASIDENTIFIER___: ConstructorScreenPresenter {
    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    
    //    private let apiClient: ApiClient
    private let flowCoordinator: FlowCoordinatorProtocol
    
    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        flowCoordinator: FlowCoordinatorProtocol
    ) {
        self.view = view
        self.flowCoordinator = flowCoordinator
        //        self.apiClient = APIClient()
    }
    
    // MARK: - Public Methods
    func configureView() {
        fetchScreen()
    }

    func handleEvent(event: ConstructorItemEvent) {
        switch event {
        case .inputChanged:
            view.inputFieldsWasUpdated()
        default:
            guard let action = event.actionParameters() else { return }
            actionTapped(action: action, statefullHandler: event.statefullHandler())
        }
    }
    
    // MARK: - Private Methods -
    // MARK: - API
    private func fetchScreen() {
//        view.setInnerTridentLoading(.loading)
//
//        apiClient.mainScreen { [weak self] result in
//            self?.view.setInnerTridentLoading(.ready)
//
//            switch result {
//            case let .success(response):
//                self?.processFetchScreenResponse(response)
//            case let.failure(error):
//                self?.handleError(error: error) {
//                    self?.fetchScreen()
//                }
//            }
//        }
    }

    private func processFetchScreenResponse(_ response: DSConstructorModel) {
        view.configure(model: response)
        handleAlertIfNeeded(alert: response.template)
    }

    // MARK: - Handlers
    private func actionTapped(action: DSActionParameter, statefullHandler: StatefullViewProtocol?) {
        switch action.type {
        case Constants.backAction:
            view.closeModule(animated: true)
        default:
            log(String(describing: action.type))
        }
    }

    private func handleAlertIfNeeded(alert: AlertTemplate?) {
        guard let alert else { return }

        TemplateHandler.handle(alert, in: view) { [weak self] action in
            switch action {
            default:
                self?.flowCoordinator.restartFlow()
            }
        }
    }

    private func handleError(error: NetworkError, retryAction: @escaping Callback) {
        GeneralErrorsHandler.process(
            error: .init(networkError: error),
            with: retryAction,
            didRetry: false,
            in: view
        )
    }
}

// MARK: - ___FILEBASENAMEASIDENTIFIER___+Constants
private extension ___FILEBASENAMEASIDENTIFIER___ {
    enum Constants {
        static let backAction = "back"
    }
}
