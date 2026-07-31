import UIKit
import DiiaMVPModule

final class DriverLicenseEditModule: BaseModule {
    private let view = DriverLicenseEditViewController()

    func viewController() -> UIViewController {
        return view
    }
}
