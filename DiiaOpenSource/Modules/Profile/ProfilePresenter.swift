import UIKit
import DiiaMVPModule

protocol ProfileAction: BasePresenter {
    func onViewDidLoad()
    func onChangePhotoTapped()
    func onRemovePhotoTapped()
    func onFieldChanged(_ field: ProfileField, value: String)
    func onBirthDateChanged(_ date: Date)
    func onBackTapped()
    func onClearAllTapped()
}

/// Editable fields of the Profile screen.
enum ProfileField {
    case firstName
    case lastName
    case middleName
    case city
    case phone
    case email
    case about
}

final class ProfilePresenter: ProfileAction {

    unowned let view: ProfileView
    private let storage: ProfileStorage

    init(view: ProfileView, storage: ProfileStorage = .shared) {
        self.view = view
        self.storage = storage
    }

    func onViewDidLoad() {
        view.display(snapshot: storage.snapshot())
    }

    func onChangePhotoTapped() {
        view.showPhotoSourcePicker()
    }

    func onRemovePhotoTapped() {
        storage.clearPhoto()
        view.display(photo: nil)
    }

    func onFieldChanged(_ field: ProfileField, value: String) {
        switch field {
        case .firstName:  storage.firstName  = value
        case .lastName:   storage.lastName   = value
        case .middleName: storage.middleName = value
        case .city:       storage.city       = value
        case .phone:      storage.phone      = value
        case .email:      storage.email      = value
        case .about:      storage.about      = value
        }
    }

    func onBirthDateChanged(_ date: Date) {
        storage.birthDate = date
    }

    func onBackTapped() {
        view.closeModule(animated: true)
    }

    func onClearAllTapped() {
        storage.apply(.init(firstName: "", lastName: "", middleName: "",
                            birthDate: nil, city: "", phone: "",
                            email: "", about: "", photo: nil))
        storage.clearPhoto()
        view.display(snapshot: storage.snapshot())
    }
}
