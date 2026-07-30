
import DiiaCommonTypes

public typealias ServiceTypeCode = String

final class PublicServiceRouteManager {
    private let routeBuilders: [ServiceTypeCode: PublicServiceRouteBuilder]
    private let categoryRouteBuilders: [String: PublicServiceCategoryRouteBuilder]

    init(routeBuilders: [PublicServiceRouteBuilder], categoryRouteBuilders: [PublicServiceCategoryRouteBuilder]) {
        self.routeBuilders = Dictionary(uniqueKeysWithValues: routeBuilders.map { ($0.key(), $0) })
        self.categoryRouteBuilders = Dictionary(uniqueKeysWithValues: categoryRouteBuilders.map { ($0.key(), $0) })
    }

    func categoryRouteFor(_ code: String) -> RouterProtocol? {
        guard let routeCreateHandler = categoryRouteBuilders[code] else {
            return nil
        }
        return routeCreateHandler.createRouter(code)
    }
    
    func routeFor(_ publicService: PublicServiceShortViewModel) -> RouterProtocol? {
        guard let routeCreateHandler = routeBuilders[publicService.type] else {
            return nil
        }
        return routeCreateHandler.createRouter(publicService)
    }
    
    func canRoute(to serviceType: ServiceTypeCode) -> Bool {
        return routeBuilders.keys.contains(serviceType)
    }
}
