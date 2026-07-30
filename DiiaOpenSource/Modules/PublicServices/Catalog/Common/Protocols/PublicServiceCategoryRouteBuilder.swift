
import Foundation
import DiiaCommonTypes

protocol PublicServiceCategoryRouteBuilder {
    func key() -> String
    func createRouter(_ categoryCode: String) -> RouterProtocol?
}
