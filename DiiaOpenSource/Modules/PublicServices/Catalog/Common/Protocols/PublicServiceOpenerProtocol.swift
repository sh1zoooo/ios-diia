
import Foundation
import DiiaMVPModule
import DiiaCommonTypes

protocol PublicServiceOpenerProtocol {
    /**
    Main method that starts opening specific Public service in response of user's choice .
    - parameter type - string for identifying which Module must be created
    - parameter contextMenu - items for generating ContextMenuProvider, may be backend provided
    - parameter view - view show show new module on
    */
    func openPublicService(_ publicService: PublicServiceShortViewModel, in view: BaseView)
    func canOpenPublicService(_ publicService: String) -> Bool
    func openCategory(code: String, in view: BaseView)
}
