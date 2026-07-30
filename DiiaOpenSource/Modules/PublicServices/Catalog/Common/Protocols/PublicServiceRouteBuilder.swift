
import Foundation
import DiiaCommonTypes

protocol PublicServiceRouteBuilder {
    func key() -> String
    func createRouter(_ publicService: PublicServiceShortViewModel) -> RouterProtocol?
}
