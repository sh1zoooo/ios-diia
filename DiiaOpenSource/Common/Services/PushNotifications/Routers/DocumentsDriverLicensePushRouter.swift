
import UIKit
import DiiaCommonTypes
import DiiaMVPModule
import DiiaUIComponents
import DiiaDocumentsCommonTypes

struct DocumentsDriverLicensePushRouteBuilder: PushRouteBuilder {
    static let key = "documents/driverLicense"

    func create(payload: PushNotificationPayload) -> RouterProtocol? {
        if canCreateRoute(with: payload) {
            return DocumentsDriverLicensePushRouter(storeHelper: StoreHelper.instance)
        }
        return nil
    }
}

struct DocumentsDriverLicensePushRouter: RouterProtocol {
    private let storeHelper: StoreHelperProtocol
    
    init(storeHelper: StoreHelperProtocol) {
        self.storeHelper = storeHelper
    }
    
    func route(in view: BaseView) {
        AppRouter.instance.popToTab(with: .documents(type: .driverLicense))
    }
}
