import UIKit
import FirebaseCore
import DiiaMVPModule
import DiiaNetwork
import DiiaCommonTypes
import DiiaCommonServices
import DiiaUIComponents

class AppConfigurator {
    static var storeHelper: StoreHelperProtocol = StoreHelper.instance

    static func configureApp() {
        if storeHelper.getValue(forKey: .hasAppBeenLaunchedBefore) != true {
            storeHelper.clearAllData()
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // FORK: the no-login boot flow skips StartAuthorizationPresenter, which is the
        // only place that normally sets this flag to true. Without it, the check above
        // would call clearAllData() on every single launch, wiping the driver-license
        // card (and anything else in StoreHelper) each time the app restarts.
        storeHelper.save(true, type: Bool.self, forKey: .hasAppBeenLaunchedBefore)

        let mirgateService = MigrationService()
        mirgateService.migrateIfNeeded()

        // Rebuilds the driver-license card from DriverLicenseStorage on every launch
        // (cheap + idempotent), so it's always in sync with whatever the user entered
        // in Settings, even if StoreHelper was cleared for some other reason.
        DriverLicenseSeeder.sync(storeHelper: storeHelper)
        // FORK: also seed the local-only passport and birth-certificate cards.
        // Even if hidden in Settings, they stay in storage so toggling them on
        // later shows the card without an app restart.
        PassportSeeder.sync(storeHelper: storeHelper)
        BirthCertificateSeeder.sync(storeHelper: storeHelper)

        // FORK: install kebab-button overlay swizzle on DSDocumentWithPhotoView
        // so all three local cards (passport / birth-certificate / driver-license)
        // show a black "⋯" button next to the bottomHeading, like the real Diia.
        DSDocumentWithPhotoView.forkInstallKebabSwizzle()

        FailableDecodableConfig.errorReporter = CrashlyticsErrorRecorder()

        // Adjusting DiiaNetwork.NetworkConfiguration must precede any work with packages
        // because they may rely on networking contex
        configureNetwork()
        
        FontBook.mainFont = AppMainFont()
        FontBook.headingFont = AppHeadingFont()
        UIComponentsConfiguration.shared.setup(imageLoader: nil, urlOpener: URLOpenerImpl(), logger: PrintLogger())

        let deepLinkManager = DeepLinkManager()
        deepLinkManager.appRouter = AppRouter.instance
        let routingHandler = RoutingHandler(appRouter: AppRouter.instance)
        TemplateHandler.setup(context: .init(router: routingHandler,
                                             deepLink: deepLinkManager,
                                             communicationHelper: URLOpenerImpl()))
        
        FirebaseApp.configure()
    }

    static private func configureNetwork() {
        let networkConfigurator = NetworkConfiguration.default
        networkConfigurator.set(serverTrustPolicies: networkConfigurator.activeServerTrustPolicies())
        networkConfigurator.set(interceptor: AuthorizationInterceptor())
        if EnvironmentVars.isInDebug {
            networkConfigurator.set(logger: EnvironmentVars.logger)
        }
        networkConfigurator.set(httpStatusCodeHandler: HTTPStatusCodeAdapter())
        networkConfigurator.set(jsonDecoderConfig: JSONDecoderConfig())
        networkConfigurator.set(responseErrorHandler: CrashlyticsErrorRecorder())
        networkConfigurator.set(analyticsHandler: AnaliticsNetworkAdapter())
    }
}

class RoutingHandler: RoutingHandlerProtocol {
    private let appRouter: AppRouter

    internal init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func performPresenting(action: @escaping (BaseView?) -> Void) {
        appRouter.performOrDefer(action: action, needPincode: false)
    }
    func popToPublicServices() {
        appRouter.popToTab(with: .publicService)
    }
    
    func popToFeed() {
        appRouter.popToTab(with: .feed)
    }
    
    func popToDocuments() {
        appRouter.popToTab(with: .documents(type: nil))
    }
}

