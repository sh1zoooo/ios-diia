import UIKit
import DiiaMVPModule

final class ProfileModule: BaseModule {
    private let view: ProfileViewController
    private let presenter: ProfilePresenter

    init() {
        view = ProfileViewController.storyboardInstantiate()
        presenter = ProfilePresenter(view: view)
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
