
import Foundation
import DiiaMVPModule
import DiiaCommonTypes

class GenericPublicServiceRouteBuilder: PublicServiceRouteBuilder {
    private let serviceKey: String
    private let route: RouterProtocol
    
    init(key: String, route: RouterProtocol) {
        self.serviceKey = key
        self.route = route
    }
    
    func key() -> String {
        return serviceKey
    }
    
    func createRouter(_ publicService: PublicServiceShortViewModel) -> RouterProtocol? {
        return route
    }
}

class GenericPublicServiceCallbackRouteBuilder: PublicServiceRouteBuilder {
    private let serviceKey: String
    private let routeCallback: (PublicServiceShortViewModel) -> RouterProtocol
    
    init(key: String, routeCallback: @escaping (PublicServiceShortViewModel) -> RouterProtocol) {
        self.serviceKey = key
        self.routeCallback = routeCallback
    }
    
    func key() -> String {
        return serviceKey
    }
    
    func createRouter(_ publicService: PublicServiceShortViewModel) -> RouterProtocol? {
        return routeCallback(publicService)
    }
}
