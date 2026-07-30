
import UIKit
import DiiaNetwork
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import DiiaCommonServices

final class ___FILEBASENAMEASIDENTIFIER___: ConstructorModalScreenPresenter {
    // MARK: - Properties
    unowned var view: ConstructorModalScreenViewProtocol

//    private let apiClient: ApiClient

    private var didRetry = false

    // MARK: - Init
    init(view: ConstructorModalScreenViewProtocol) {
        self.view = view
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

    // MARK: - Private Methods
    // MARK: - API Methods
    private func fetchScreen() {
//        view.setLoadingState(.loading)
//        apiClient.getScreen { [weak self] result in
//            guard let self else { return }
//            self.view.setLoadingState(.ready)
//            switch result {
//            case .success(let response):
//                self.didRetry = false
//                self.processResponse(response)
//            case .failure(let error):
//                self.handleError(error: error) {[weak self] in
//                    self?.fetchScreen()
//                }
//            }
//        }
    }
    
    // MARK: - Private Methods
    private func actionTapped(action: DSActionParameter, statefullHandler: StatefullViewProtocol?) {
        switch action.type {
        case Constants.backAction:
            view.closeModule(animated: true)
        default:
            log(String(describing: action.type))
        }
    }
    
    private func processResponse(_ response: DSConstructorModel) {
        view.configure(model: response)
        handleAlertIfNeeded(alert: response.template)
    }
    
    // MARK: - Handlers
    private func handleAlertIfNeeded(alert: AlertTemplate?) {
        guard let alert else { return }

        TemplateHandler.handle(alert, in: view) { [weak self] action in
            switch action {
            default:
                return
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
    
    private func handleCriticalError(error: NetworkError, retryAction: @escaping Callback) {
        GeneralErrorsHandler.process(
            error: .init(networkError: error),
            with: { [weak self] in
                self?.didRetry = true
                retryAction()
            },
            didRetry: didRetry,
            in: view
        )
    }
}

// MARK: - Constants
private extension ___FILEBASENAMEASIDENTIFIER___ {
    enum Constants {
        static let backAction = "back"
    }
}
