
import Foundation
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaCommonServices

final class PublicServiceOpener: PublicServiceOpenerProtocol {

    private let bag = DisposeBag()
    private var publicServiceResponse: PublicServiceResponse?
    private var isUpdating = false
    private let apiClient: PublicServicesAPIClientProtocol
    private let serviceRouteManager: PublicServiceRouteManager

    /**
     Main actor that is able to handle user's intention to open specific Public service.
    - parameter apiClient - api client for running requests for updating list of public services
    */
    public init(apiClient: PublicServicesAPIClientProtocol, routeManager: PublicServiceRouteManager) {
        self.apiClient = apiClient
        self.serviceRouteManager = routeManager
    }
    
    // MARK: - PublicServiceOpenerProtocol
    func openPublicService(_ publicService: PublicServiceShortViewModel, in view: any BaseView) {
        guard let serviceRoute = serviceRouteManager.routeFor(publicService) else {
            return
        }

        serviceRoute.route(in: view)
    }
    
    public func canOpenPublicService(_ type: String) -> Bool {
        return serviceRouteManager.canRoute(to: type)
    }
    
    public func openCategory(code: String, in view: BaseView) {
        if isUpdating { return }
        if let publicServiceResponse = publicServiceResponse {
            if let category = publicServiceResponse.publicServicesCategories
                .first(where: { $0.code == code }) {
                if category.requiresPrestartWarning == true {
                    openCategoryWithWarning(category, in: view)
                    return
                }
                let validatorTask: PublicServiceCodeValidator = { [weak self] code in
                    self?.canOpenPublicService(code) ?? false
                }
                view.open(module: PublicServiceCategoryModule(category: PublicServiceCategoryViewModel(model: category, typeValidator: validatorTask), opener: self))
            }
        } else {
            updatePublicServices(completion: { [weak self, weak view] in
                guard let view = view else { return }
                self?.openCategory(code: code, in: view)
            }, in: view)
        }
    }
    
    // MARK: - Private helper methods
    private func updatePublicServices(completion: Callback? = nil, in view: BaseView) {
        guard !self.isUpdating else { return }
        self.isUpdating = true
        view.showProgress()
        apiClient
            .getPublicServices()
            .observe { [weak self, weak view] event in
                guard let self = self else { return }
                self.isUpdating = false
                switch event {
                case .next(let response):
                    view?.hideProgress()
                    self.publicServiceResponse = response
                    completion?()
                case .failed:
                    view?.hideProgress()
                case .completed:
                    return
                }
            }.dispose(in: bag)
    }
    
    private func openCategoryWithWarning(_ category: PublicServiceCategory, in view: BaseView) {
        view.showProgress()
        apiClient.getPrestartWarning(category: category.code, service: nil) { [weak self, weak view] result in
            guard let self, let view else { return }
            view.hideProgress()
            switch result {
            case .success(let alert):
                TemplateHandler.handle(alert.template, in: view) { [weak self, weak view] action in
                    if let view, action == AlertTemplateAction("continue_after_prestart_warning") {
                        self?.openCategoryWithWarningForced(category, in: view)
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    private func openCategoryWithWarningForced(_ category: PublicServiceCategory, in view: BaseView) {
        if let route = serviceRouteManager.categoryRouteFor(category.code) {
            route.route(in: view)
            return
        }
        let validatorTask: PublicServiceCodeValidator = { [weak self] code in
            self?.canOpenPublicService(code) ?? false
        }
        if category.publicServices.count == 1, let service = category.publicServices.first {
            openPublicService(.init(model: service, validator: validatorTask), in: view)
            return
        }
        view.open(module: PublicServiceCategoryModule(category: PublicServiceCategoryViewModel(model: category, typeValidator: validatorTask), opener: self))
    }
}
