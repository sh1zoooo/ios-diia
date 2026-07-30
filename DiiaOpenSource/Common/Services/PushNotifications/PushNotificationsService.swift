import Foundation
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaAuthorization
import UserNotifications

final class PushNotificationsService: NSObject {
    
    // MARK: - Properties
    private let notificationCenter: UNUserNotificationCenter
    var router: AppRouter?

    // MARK: - Init
    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Public Methods
    func askNotificationsPermission(withHandler handler: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { isGranted, err in
            onMainQueue {
                if err != nil {
                    return
                }
                
                handler(isGranted)
            }
        }
    }
}

extension PushNotificationsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping Callback) {
        guard let notificationPayload = getPayload(from: response.notification.request.content.userInfo) else {
            completionHandler()
            
            return
        }
        
        processPayloadAction(notificationPayload)
        completionHandler()
    }
    
    private func getPayload(from userInfo: [AnyHashable: Any]) -> PushNotificationPayload? {
        guard
            let userInfoDict = userInfo as? [String: Any],
            let rawPayloadDict = userInfoDict[Constants.payloadKey] as? [String: Any],
            let rawPayloadData = try? JSONSerialization.data(withJSONObject: rawPayloadDict, options: []),
            let payload = try? JSONDecoder().decode(PushNotificationPayload.self, from: rawPayloadData)
        else {
            return nil
        }
        
        return payload
    }
    
    // swiftlint: disable all
    private func processPayloadAction(_ payload: PushNotificationPayload) {
        if let routerBuilder = PushRoutersList.routeBuildersDictionary[payload.action.type],
           let router = routerBuilder.create(payload: payload) {
            let needAuth = routerBuilder.needAuth() || payload.needAuth
            self.router?.performOrDefer(
                action: { view in
                    guard let view else { return }
                    router.route(in: view)
                },
                needPincode: needAuth)
        }
    }
}

// MARK: - Constants
extension PushNotificationsService {
    private enum Constants {
        static let payloadKey = "payload"
        static let actionKey = "action"
        static let typeKey = "type"
        static let subType = "subtype"
    }
}
