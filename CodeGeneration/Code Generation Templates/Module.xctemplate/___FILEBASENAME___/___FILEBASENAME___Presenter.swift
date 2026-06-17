
import UIKit
import DiiaNetwork
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import DiiaCommonServices

final class ___FILEBASENAMEASIDENTIFIER___: ConstructorScreenPresenter {
    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    
//    private let apiClient: ApiClientProtocol
    private let flowCoordinator: FlowCoordinatorProtocol
    
    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        flowCoordinator: FlowCoordinatorProtocol
//        apiClient: ApiClientProtocol = ApiClient()
    ) {
        self.view = view
        self.flowCoordinator = flowCoordinator
//        self.apiClient = apiClient
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
//        view.setLoadingState(.loading)
//
//        apiClient.mainScreen { [weak self] result in
//            guard let self else { return }
//            self.view.setLoadingState(.ready)
//            switch result {
//            case .success(let response):
//                self.processFetchScreenResponse(response)
//            case .failure(let error):
//                self.handleError(error: error) { [weak self] in
//                    self?.fetchScreen()
//                }
//            }
//        }
    }

    // MARK: - Handlers
    private func processFetchScreenResponse(_ response: DSConstructorModel) {
        view.configure(model: response)
        handleAlertIfNeeded(alert: response.template)
    }

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
