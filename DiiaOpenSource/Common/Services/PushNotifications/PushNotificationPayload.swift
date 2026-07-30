
import Foundation
import DiiaUIComponents
import DiiaCommonTypes

struct PushNotificationPayload: Codable {
    let needAuth: Bool
    let notificationId: String
    let action: PushNotificationAction
    let unread: Int?
}

struct PushNotificationAction: Codable {
    let type: String
    let subtype: String?
    let resourceId: String?
}
