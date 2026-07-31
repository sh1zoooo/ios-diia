import UIKit

/// FORK: simple form for filling in the passport fields. Plain UIKit, no storyboard.
/// Mirrors DriverLicenseEditViewController.
final class PassportEditViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        return s
    }()

    private let photoButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 12
        b.layer.masksToBounds = true
        b.backgroundColor = .secondarySystemBackground
        b.setTitle("Додати фото", for: .normal)
        b.contentVerticalAlignment = .fill
        b.contentHorizontalAlignment = .fill
        b.imageView?.contentMode = .scaleAspectFill
        b.heightAnchor.constraint(equalToConstant: 160).isActive = true
        b.widthAnchor.constraint(equalToConstant: 160).isActive = true
        return b
    }()

    private let surnameField     = PassportEditViewController.makeField(placeholder: "Прізвище")
    private let firstNameField   = PassportEditViewController.makeField(placeholder: "Ім’я")
    private let middleNameField  = PassportEditViewController.makeField(placeholder: "По батькові")
    private let birthDateField   = PassportEditViewController.makeField(placeholder: "Дата народження (напр. 24.08.1991)")
    private let numberField      = PassportEditViewController.makeField(placeholder: "Серія та номер (напр. ФО 123456)")

    private let signatureButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Намалювати підпис", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .secondarySystemBackground
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return b
    }()

    private lazy var textFields: [UITextField] = [
        surnameField, firstNameField, middleNameField, birthDateField, numberField
    ]

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Зберегти", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.backgroundColor = .black
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Паспорт громадянина України"
        view.backgroundColor = .systemBackground
        setupLayout()
        loadCurrentValues()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)
        signatureButton.addTarget(self, action: #selector(signatureTapped), for: .touchUpInside)
        textFields.forEach { $0.delegate = self }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        photoButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        let photoWrapper = UIStackView(arrangedSubviews: [photoButton])
        photoWrapper.axis = .horizontal
        photoWrapper.alignment = .center
        stackView.addArrangedSubview(photoWrapper)
        textFields.forEach { stackView.addArrangedSubview($0) }
        stackView.addArrangedSubview(signatureButton)
    }

    private func loadCurrentValues() {
        let s = PassportStorage.shared.snapshot()
        surnameField.text     = s.surname
        firstNameField.text   = s.firstName
        middleNameField.text  = s.middleName
        birthDateField.text   = s.birthDate
        numberField.text      = s.number
        updatePhotoButton()
    }

    private func updatePhotoButton() {
        if let photo = PassportStorage.shared.photo {
            photoButton.setImage(photo, for: .normal)
            photoButton.setTitle(nil, for: .normal)
        } else {
            photoButton.setImage(nil, for: .normal)
            photoButton.setTitle("Додати фото", for: .normal)
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func photoTapped() {
        let sheet = UIAlertController(title: "Фото на документ", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Камера", style: .default) { [weak self] _ in self?.presentPicker(source: .camera) })
        sheet.addAction(UIAlertAction(title: "Галерея", style: .default) { [weak self] _ in self?.presentPicker(source: .photoLibrary) })
        if PassportStorage.shared.photo != nil {
            sheet.addAction(UIAlertAction(title: "Видалити фото", style: .destructive) { [weak self] _ in
                PassportStorage.shared.clearPhoto()
                self?.updatePhotoButton()
                PassportSeeder.sync()
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        sheet.popoverPresentationController?.sourceView = photoButton
        sheet.popoverPresentationController?.sourceRect = photoButton.bounds
        present(sheet, animated: true)
    }

    private func presentPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func signatureTapped() {
        // Push the signature editor inside the same navigation stack so the
        // user comes back to this form after saving.
        navigationController?.pushViewController(SignatureEditorViewController(), animated: true)
    }

    @objc private func saveTapped() {
        PassportStorage.shared.apply(
            .init(surname: surnameField.text ?? "",
                  firstName: firstNameField.text ?? "",
                  middleName: middleNameField.text ?? "",
                  birthDate: birthDateField.text ?? "",
                  number: numberField.text ?? "",
                  issuedBy: PassportStorage.shared.issuedBy,
                  issuedDate: PassportStorage.shared.issuedDate,
                  validUntil: PassportStorage.shared.validUntil,
                  recordNumber: PassportStorage.shared.recordNumber)
        )
        PassportSeeder.sync()
        navigationController?.popViewController(animated: true)
    }

    private static func makeField(placeholder: String) -> UITextField {
        let f = UITextField()
        f.placeholder = placeholder
        f.borderStyle = .roundedRect
        f.font = .systemFont(ofSize: 16)
        f.returnKeyType = .next
        f.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return f
    }
}

extension PassportEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let i = textFields.firstIndex(of: textField) else { textField.resignFirstResponder(); return true }
        if i + 1 < textFields.count { textFields[i + 1].becomeFirstResponder() } else { textField.resignFirstResponder() }
        return true
    }
}

extension PassportEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else { return }
        PassportStorage.shared.savePhoto(image)
        updatePhotoButton()
        PassportSeeder.sync()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
