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
        // FORK: Profile + a "Картки документів" section with toggles for each
        // local card + per-card edit row. Pincode / biometry remain hidden
        // (no logged-in user).
        var settings: [SettingsViewModel] = [
            .titled(
                vm: TitleCellViewModel(
                    title: "Профіль",
                    iconName: R.image.menuDiiaID.name,
                    action: { [weak view] in view?.open(module: ProfileModule()) }
                )
            )
        ]

        // --- Картки документів: visibility toggles --------------------------------
        for kind in DocumentVisibilityStorage.DocKind.allCases {
            settings.append(
                .switched(vm: SwitchIconedViewModel(
                    title: kind.displayName,
                    iconName: kind.iconName,
                    isOn: DocumentVisibilityStorage.shared.isVisible(kind),
                    onSwitch: { isOn in
                        DocumentVisibilityStorage.shared.setVisible(isOn, for: kind)
                        // Refresh the seeded card so the Documents tab picks up the
                        // new visibility state without an app restart.
                        switch kind {
                        case .passport:           PassportSeeder.sync()
                        case .birthCertificate:   BirthCertificateSeeder.sync()
                        case .driverLicense:      DriverLicenseSeeder.sync()
                        }
                    }
                ))
            )
        }

        // --- Редагування карток ---------------------------------------------------
        settings.append(.titled(
            vm: TitleCellViewModel(
                title: "Редагувати: Паспорт",
                iconName: R.image.menuDiiaID.name,
                action: { [weak view] in view?.open(module: PassportEditModule()) }
            )
        ))
        settings.append(.titled(
            vm: TitleCellViewModel(
                title: "Редагувати: Актовий запис про народження",
                iconName: R.image.orderIcon.name,
                action: { [weak view] in view?.open(module: BirthCertificateEditModule()) }
            )
        ))
        settings.append(.titled(
            vm: TitleCellViewModel(
                title: "Редагувати: Посвідчення водія",
                iconName: R.image.orderIcon.name,
                action: { [weak view] in view?.open(module: DriverLicenseEditModule()) }
            )
        ))

        // --- Інші -----------------------------------------------------------------
        settings.append(
            .switched(vm: SwitchIconedViewModel(
                title: "Відкривати посилання по тапу на QR",
                iconName: R.image.orderIcon.name,
                isOn: DocumentVisibilityStorage.shared.isQRTapToOpenEnabled,
                onSwitch: { isOn in
                    DocumentVisibilityStorage.shared.isQRTapToOpenEnabled = isOn
                }
            ))
        )
        settings.append(.titled(
            vm: TitleCellViewModel(
                title: R.Strings.settings_docs_order.localized(),
                iconName: R.image.orderIcon.name,
                action: { [weak view] in view?.open(module: DocumentsReorderingModule()) }
            )
        ))

        self.settings = settings
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
