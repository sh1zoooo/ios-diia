import UIKit
import DiiaMVPModule
import DiiaAuthorizationPinCode

protocol SettingsAction: BasePresenter {
    func onBackTapped()
    func numberOfItems() -> Int
    func item(at indexPath: IndexPath) -> SettingsViewModel?
}

final class SettingsPresenter: SettingsAction {
    
    // MARK: - Properties
    unowned var view: SettingsView
    private let settingsManager = SettingsManager.instance
    private var settings: [SettingsViewModel] = []
    
    // MARK: - Init
    init(view: SettingsView) {
        self.view = view
        prepareSettings()
    }
    
    private func prepareSettings() {
        // FORK: only Profile + Documents order remain. Pincode and biometry
        // don't make sense without a logged-in user, so they are hidden.
        let settings: [SettingsViewModel] = [
            .titled(
                vm: TitleCellViewModel(
                    title: "Профіль",
                    iconName: R.image.menuDiiaID.name,
                    action: { [weak view] in view?.open(module: ProfileModule()) }
                )
            ),
            .titled(
                vm: TitleCellViewModel(
                    title: R.Strings.settings_docs_order.localized(),
                    iconName: R.image.orderIcon.name,
                    action: { [weak view] in view?.open(module: DocumentsReorderingModule()) }
                )
            )
        ]

        self.settings = settings
    }
    
    private func prepareBiometrySettingsViewModel() -> SwitchIconedViewModel? {
        let biometryText: String
        let biometryIcon: String
        
        switch BiometryHelper.biometricType() {
        case .face:
            biometryText = R.Strings.menu_allow_face_id.localized()
            biometryIcon = R.image.menuFaceID.name
        case .touch:
            biometryText = R.Strings.menu_allow_touch_id.localized()
            biometryIcon = R.image.menuTouchID.name
        default:
            return nil
        }
        
        return SwitchIconedViewModel(title: biometryText,
                               iconName: biometryIcon,
                               isOn: settingsManager.isBiometryAllowed(),
                               onSwitch: { [weak self] (isOn) in
                                   self?.settingsManager.setBiometry(isAllowed: isOn)
                               })
    }
    
    // MARK: - SettingsAction
    func onBackTapped() {
        view.closeModule(animated: true)
    }
    
    func numberOfItems() -> Int {
        return settings.count
    }
    
    func item(at indexPath: IndexPath) -> SettingsViewModel? {
        guard settings.indices.contains(indexPath.row) else { return nil }
        
        return settings[indexPath.row]
    }
}
