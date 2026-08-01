import UIKit

/// FORK: driver-license edit form, redesigned in Diia style via ForkEditFormBuilder.
final class DriverLicenseEditViewController: UIViewController {

    private var fullName: String = ""
    private var birthDate: String = ""
    private var category: String = ""
    private var number: String = ""
    private var validUntil: String = ""

    private var avatarView: ForkAvatarView?
    private var textFields: [UITextField] = []

    private lazy var photoPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Посвідчення водія"
        loadCurrentValues()
        buildForm()
    }

    private func buildForm() {
        let result = ForkEditFormBuilder.build(
            in: self,
            title: "Посвідчення водія",
            subtitle: "Заповніть дані документа",
            sections: [
                .init(title: "Особисті дані", fields: [
                    .text(icon: UIImage(systemName: "person"),
                         label: "ПРІЗВИЩЕ, ІМ’Я, ПО БАТЬКОВІ",
                         placeholder: "Прізвище Ім’я По-батькові",
                         value: fullName,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.fullName = v }),
                    .text(icon: UIImage(systemName: "calendar"),
                         label: "ДАТА НАРОДЖЕННЯ",
                         placeholder: "напр. 24.08.1991",
                         value: birthDate,
                         keyboardType: .numbersAndPunctuation,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.birthDate = v }),
                ]),
                .init(title: "Дані посвідчення", fields: [
                    .text(icon: UIImage(systemName: "list.clipboard"),
                         label: "КАТЕГОРІЇ",
                         placeholder: "напр. B, C",
                         value: category,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.category = v }),
                    .text(icon: UIImage(systemName: "number"),
                         label: "НОМЕР ПОСВІДЧЕННЯ",
                         placeholder: "Номер посвідчення",
                         value: number,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.number = v }),
                    .text(icon: UIImage(systemName: "calendar.badge.clock"),
                         label: "ДІЙСНЕ ДО",
                         placeholder: "напр. 20.05.2024",
                         value: validUntil,
                         keyboardType: .numbersAndPunctuation,
                         returnKey: .done,
                         onChange: { [weak self] v in self?.validUntil = v }),
                ]),
            ],
            avatar: .init(image: DriverLicenseStorage.shared.photo,
                          placeholderInitial: "В",
                          onTap: { [weak self] in self?.photoTapped() }),
            primaryButton: .init(title: "Зберегти", style: .primary, action: { [weak self] in self?.saveTapped() }),
            secondaryButton: .init(title: "Скасувати", style: .secondary, action: { [weak self] in self?.cancelTapped() }),
            backAction: { [weak self] in self?.cancelTapped() }
        )
        self.textFields = result.textFields
        self.avatarView = result.avatarView
        textFields.enumerated().forEach { idx, tf in
            tf.delegate = self
            tf.tag = idx
        }
    }

    private func loadCurrentValues() {
        let s = DriverLicenseStorage.shared.snapshot()
        fullName = s.fullName
        birthDate = s.birthDate
        category = s.category
        number = s.number
        validUntil = s.validUntil
    }

    @objc private func saveTapped() {
        DriverLicenseStorage.shared.apply(
            .init(fullName: fullName,
                  birthDate: birthDate,
                  category: category,
                  number: number,
                  issuedBy: DriverLicenseStorage.shared.issuedBy,
                  validUntil: validUntil)
        )
        DriverLicenseSeeder.sync()
        navigationController?.popViewController(animated: true)
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func photoTapped() {
        let sheet = UIAlertController(title: "Фото на документ", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(.init(title: "Камера", style: .default) { [weak self] _ in self?.presentPicker(source: .camera) })
        }
        sheet.addAction(.init(title: "Галерея", style: .default) { [weak self] _ in self?.presentPicker(source: .photoLibrary) })
        if DriverLicenseStorage.shared.photo != nil {
            sheet.addAction(.init(title: "Видалити фото", style: .destructive) { [weak self] _ in
                DriverLicenseStorage.shared.clearPhoto()
                self?.avatarView?.update(image: nil)
                DriverLicenseSeeder.sync()
            })
        }
        sheet.addAction(.init(title: "Скасувати", style: .cancel))
        sheet.popoverPresentationController?.sourceView = avatarView ?? view
        sheet.popoverPresentationController?.sourceRect = avatarView?.bounds ?? view.bounds
        present(sheet, animated: true)
    }

    private func presentPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        photoPicker.sourceType = source
        present(photoPicker, animated: true)
    }
}

extension DriverLicenseEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let idx = textField.tag
        if idx + 1 < textFields.count {
            textFields[idx + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension DriverLicenseEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true)
        guard let image = image else { return }
        DriverLicenseStorage.shared.savePhoto(image)
        avatarView?.update(image: DriverLicenseStorage.shared.photo)
        DriverLicenseSeeder.sync()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
