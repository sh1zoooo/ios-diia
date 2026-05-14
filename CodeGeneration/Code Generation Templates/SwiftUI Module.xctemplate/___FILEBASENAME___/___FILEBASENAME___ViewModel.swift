//___FILEHEADER___

import SwiftUI
import DiiaUIComponents
import DiiaMVPModule
import DiiaCommonTypes

class ___FILEBASENAMEASIDENTIFIER___: ObservableObject {
    let contextMenu: ContextMenuProviderProtocol
    let flowCoordinator: FlowCoordinatorProtocol
    var navigation: NavigationHolder
    
    init(flowCoordinator: FlowCoordinatorProtocol,
         contextMenu: ContextMenuProviderProtocol,
         navigation: NavigationHolder = NavigationHolder()
    ) {
        self.flowCoordinator = flowCoordinator
        self.contextMenu = contextMenu
        self.navigation = navigation
    }
}
