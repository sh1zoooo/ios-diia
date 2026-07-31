import UIKit
import DiiaMVPModule

final class BirthCertificateEditModule: BaseModule {
    private let view = BirthCertificateEditViewController()

    func viewController() -> UIViewController { return view }
}
