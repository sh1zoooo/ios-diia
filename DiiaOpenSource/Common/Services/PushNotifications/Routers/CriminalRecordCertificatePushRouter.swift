
import UIKit
import DiiaCommonTypes
import DiiaMVPModule
import DiiaUIComponents
import DiiaPublicServices

struct CriminalRecordCertificatePushRouteBuilder: PushRouteBuilder {
    static let key = "criminalRecordCertificate"

    func create(payload: PushNotificationPayload) -> RouterProtocol? {
        if canCreateRoute(with: payload) {
            return CriminalRecordCertificatePushRouter(payload: payload)
        }
        return nil
    }
}

struct CriminalRecordCertificatePushRouter: RouterProtocol {
    private let payload: PushNotificationPayload
    
    init(payload: PushNotificationPayload) {
        self.payload = payload
    }
    
    func route(in view: BaseView) {
        if let applicationId = payload.action.resourceId {
            let baseCMP = BaseContextMenuProvider(publicService: .criminalRecordCertificate)
            let module = CriminalExtractStatusModule(
                contextMenuProvider: baseCMP,
                flowCoordinator: CriminalExtractCoordinatorImpl(rootView: view),
                config: .create(),
                applicationId: applicationId)
            view.open(module: module)
        }
    }
}
