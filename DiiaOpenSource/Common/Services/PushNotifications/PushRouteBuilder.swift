
import Foundation
import DiiaUIComponents
import DiiaCommonTypes

protocol PushRouteBuilder {
    static var key: String { get }
    func canCreateRoute(with payload: PushNotificationPayload) -> Bool
    func needAuth() -> Bool
    func create(payload: PushNotificationPayload) -> RouterProtocol?
}

extension PushRouteBuilder {
    func canCreateRoute(with payload: PushNotificationPayload) -> Bool {
        return payload.action.type == Self.key
    }
    
    func needAuth() -> Bool {
        return true
    }
}

enum PushRoutersList {
    static let routeBuildersDictionary: [String: PushRouteBuilder] = [
        CriminalRecordCertificatePushRouteBuilder.key: CriminalRecordCertificatePushRouteBuilder(),
        DocumentsDriverLicensePushRouteBuilder.key: DocumentsDriverLicensePushRouteBuilder()
    ]
}
