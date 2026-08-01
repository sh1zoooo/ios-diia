import UIKit

/// FORK: passport edit form, redesigned in Diia style (animated gradient bg,
/// white rounded cards, custom input fields with icons).
///
/// Uses ForkEditFormBuilder for the layout. Photo picker + signature editor
/// are reached via two button-rows in the second card.
final class PassportEditViewController: UIViewController {

    // Storage references kept as instance properties so closures can read/write them.
    private var surname: String = ""
    private var firstName: String = ""
    private var middleName: String = ""
    private var birthDate: String = ""
    private var number: String = ""

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
        navigationItem.title = "Паспорт"
        loadCurrentValues()
        buildForm()
    }

    // MARK: - Form

    private func buildForm() {
        let result = ForkEditFormBuilder.build(
            in: self,
            title: "Паспорт громадянина України",
            subtitle: "Заповніть дані документа",
            sections: [
                .init(title: "Особисті дані", fields: [
                    .text(icon: UIImage(systemName: "person"),
                         label: "ПРІЗВИЩЕ",
                         placeholder: "Прізвище",
                         value: surname,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.surname = v }),
                    .text(icon: UIImage(systemName: "person"),
                         label: "ІМ’Я",
                         placeholder: "Ім’я",
                         value: firstName,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.firstName = v }),
                    .text(icon: UIImage(systemName: "person"),
                         label: "ПО БАТЬКОВІ",
                         placeholder: "По батькові",
                         value: middleName,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.middleName = v }),
                ]),
                .init(title: "Дані документа", fields: [
                    .text(icon: UIImage(systemName: "calendar"),
                         label: "ДАТА НАРОДЖЕННЯ",
                         placeholder: "напр. 24.08.1991",
                         value: birthDate,
                         keyboardType: .numbersAndPunctuation,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.birthDate = v }),
                    .text(icon: UIImage(systemName: "number"),
                         label: "СЕРІЯ ТА НОМЕР",
                         placeholder: "напр. ФО 123456",
                         value: number,
                         keyboardType: .default,
                         returnKey: .done,
                         onChange: { [weak self] v in self?.number = v }),
                    .buttonRow(icon: UIImage(systemName: "signature"),
                               label: "Намалювати підпис",
                               onTap: { [weak self] in self?.openSignatureEditor() }),
                ]),
            ],
            avatar: .init(image: PassportStorage.shared.photo,
                          placeholderInitial: "П",
                          onTap: { [weak self] in self?.photoTapped() }),
            primaryButton: .init(title: "Зберегти", style: .primary, action: { [weak self] in self?.saveTapped() }),
            secondaryButton: .init(title: "Скасувати", style: .secondary, action: { [weak self] in self?.cancelTapped() }),
            backAction: { [weak self] in self?.cancelTapped() }
        )
        self.textFields = result.textFields
        self.avatarView = result.avatarView
        // Make return-key cycle through fields.
        textFields.enumerated().forEach { idx, tf in
            tf.delegate = self
            tf.tag = idx
        }
    }

    // MARK: - State

    private func loadCurrentValues() {
        let s = PassportStorage.shared.snapshot()
        surname = s.surname
        firstName = s.firstName
        middleName = s.middleName
        birthDate = s.birthDate
        number = s.number
    }

    @objc private func saveTapped() {
        PassportStorage.shared.apply(
            .init(surname: surname,
                  firstName: firstName,
                  middleName: middleName,
                  birthDate: birthDate,
                  number: number,
                  issuedBy: PassportStorage.shared.issuedBy,
                  issuedDate: PassportStorage.shared.issuedDate,
                  validUntil: PassportStorage.shared.validUntil,
                  recordNumber: PassportStorage.shared.recordNumber)
        )
        PassportSeeder.sync()
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
        if PassportStorage.shared.photo != nil {
            sheet.addAction(.init(title: "Видалити фото", style: .destructive) { [weak self] _ in
                PassportStorage.shared.clearPhoto()
                self?.avatarView?.update(image: nil)
                PassportSeeder.sync()
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

    @objc private func openSignatureEditor() {
        navigationController?.pushViewController(SignatureEditorViewController(), animated: true)
    }
}

// MARK: - UITextFieldDelegate (Next cycling)
extension PassportEditViewController: UITextFieldDelegate {
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

// MARK: - UIImagePickerControllerDelegate
extension PassportEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true)
        guard let image = image else { return }
        PassportStorage.shared.savePhoto(image)
        avatarView?.update(image: PassportStorage.shared.photo)
        PassportSeeder.sync()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
