import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaPublicServices

struct PublicServiceCategoriesListModuleFactory {
    static func create() -> BaseModule {
        PublicServiceCategoriesListModule(context: .init(
            network: .create(),
            publicServiceRouteManager: .init(routeBuilders: publicServiceRouteBuilders, categoryRouteBuilders: publicServiceCategoryRouteBuilders),
            storage: PublicServicesStorageImpl.init(storage: StoreHelper.instance),
            imageNameProvider: UIComponentsConfiguration.shared.imageProvider
        ))
    }
}

struct PublicServiceOpenerFactory {
    static func create() -> PublicServiceOpener {
        PublicServiceOpener(apiClient: PublicServicesAPIClient(),
                            routeManager: .init(routeBuilders: publicServiceRouteBuilders, categoryRouteBuilders: publicServiceCategoryRouteBuilders))
    }
}

final class PublicServicesStorageImpl: PublicServicesStorage {
    private let storage: StoreHelperProtocol
    
    init(storage: StoreHelperProtocol) {
        self.storage = storage
    }
    
    func savePublicServicesResponse(response: PublicServiceResponse) {
        storage.save(response, type: PublicServiceResponse.self, forKey: .publicServiceListCache)
    }
    
    func getPublicServicesResponse() -> PublicServiceResponse? {
        storage.getValue(forKey: .publicServiceListCache)
    }
}

private let publicServiceRouteBuilders: [PublicServiceRouteBuilder] = [
    GenericPublicServiceCallbackRouteBuilder(key: PublicServiceType.criminalRecordCertificate.rawValue, routeCallback: { ps in
        return PSCriminalRecordExtractRoute(contextMenuItems: ps.contextMenu)
    })
]

private let publicServiceCategoryRouteBuilders: [PublicServiceCategoryRouteBuilder] = []
