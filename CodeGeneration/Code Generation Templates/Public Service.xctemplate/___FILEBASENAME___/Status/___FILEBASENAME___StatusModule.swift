//___FILEHEADER___

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

final class ___FILEBASENAMEASIDENTIFIER___: BaseModule {
    private let view: ConstructorViewController
    private let presenter: ___VARIABLE_productName:identifier___StatusPresenter
    
    init(
        applicationId: String,
        flowCoordinator: FlowCoordinatorProtocol
    ) {
        view = ConstructorViewController()
        presenter = ___VARIABLE_productName:identifier___StatusPresenter(
            applicationId: applicationId,
            view: view,
            flowCoordinator: flowCoordinator)
        view.presenter = presenter
    }
    
    func viewController() -> UIViewController {
        return view
    }
}
