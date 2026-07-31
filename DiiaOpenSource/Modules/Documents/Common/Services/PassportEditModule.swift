import UIKit
import DiiaMVPModule

final class PassportEditModule: BaseModule {
    private let view = PassportEditViewController()

    func viewController() -> UIViewController { return view }
}
