
import UIKit
import DiiaMVPModule
import DiiaCommonTypes

final class PublicServiceFlowCoordinator: FlowCoordinatorProtocol {
    weak var rootView: BaseView?
    var restartCallback: Callback?
    var successCallback: ((Bool) -> Void)?
    
    init(rootView: BaseView,
         restartCallback: Callback? = nil,
         successCallback: ((Bool) -> Void)? = nil) {
        self.rootView = rootView
        self.restartCallback = restartCallback
        self.successCallback = successCallback
    }
    
    func restartFlow() {
        restartCallback?()
        guard let rootView = rootView else {
            return
        }
        rootView.closeToView(view: rootView, animated: true)
    }
    
    func flowWasFinishedWithSuccess(success: Bool) {
        guard let callback = successCallback else {
            restartFlow()
            return
        }
        callback(success)
    }
    
    func restartFlow(with modules: [BaseModule]) {
        guard let vc = rootView as? UIViewController else {
            return
        }
        vc.navigationController?.view.endEditing(true)
        vc.navigationController?.replaceViewControllers(
            with: modules.map { $0.viewController() },
            after: vc.topNonNavigationParent())
        restartCallback?()
    }
    
    func closeFlow() {
        guard let vc = rootView as? UIViewController else {
            return
        }
        vc.navigationController?.replaceViewControllers(
            with: [],
            after: vc.topNonNavigationParent(),
            includingReference: true)
    }
}
