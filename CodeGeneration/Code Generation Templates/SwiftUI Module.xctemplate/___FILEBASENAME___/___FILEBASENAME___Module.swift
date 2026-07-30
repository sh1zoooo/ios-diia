 //___FILEHEADER___

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes

final class ___FILEBASENAMEASIDENTIFIER___: BaseModule {
    private let view: SwiftUIWrapperController<___VARIABLE_productName:identifier___View>
    
    init(flowCoordinator: FlowCoordinatorProtocol, contextMenu: ContextMenuProviderProtocol) {
        let vm = ___VARIABLE_productName:identifier___ViewModel(flowCoordinator: flowCoordinator, contextMenu: contextMenu)
        view = .init(content: ___VARIABLE_productName:identifier___View(viewModel: vm))
        vm.navigation.baseView = view
    }

    func viewController() -> UIViewController {
        return view
    }
}