//___FILEHEADER___

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

final class ___FILEBASENAMEASIDENTIFIER___: BaseModule {
    private let view: ___VARIABLE_productName:identifier___ViewController
    private let presenter: ___VARIABLE_productName:identifier___Presenter

    init(flowCoordinator: FlowCoordinatorProtocol) {
        view = ___VARIABLE_productName:identifier___ViewController()
        presenter = ___VARIABLE_productName:identifier___Presenter(
            view: view,
            flowCoordinator: flowCoordinator
        )
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
