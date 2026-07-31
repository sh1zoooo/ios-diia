import UIKit
import DiiaMVPModule

final class SignatureEditorModule: BaseModule {
    private let view = SignatureEditorViewController()

    func viewController() -> UIViewController { return view }
}
