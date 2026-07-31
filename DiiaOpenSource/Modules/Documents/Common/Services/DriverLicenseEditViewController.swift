import UIKit

/// FORK: simple form for filling in the driver-license fields shown in the
/// "Документи" tab. Plain UIKit, no storyboard — mirrors the storage pattern
/// used by `ProfileViewController`/`ProfileStorage`.
final class DriverLicenseEditViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.backgroundColor = .secondarySystemBackground
        button.setTitle("Додати фото", for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageView?.contentMode = .scaleAspectFill
        button.heightAnchor.constraint(equalToConstant: 160).isActive = true
        button.widthAnchor.constraint(equalToConstant: 160).isActive = true
        return button
    }()

    private let fullNameField = DriverLicenseEditViewController.makeField(placeholder: "Прізвище, ім'я, по батькові")
    private let birthDateField = DriverLicenseEditViewController.makeField(placeholder: "Дата народження (напр. 24.08.1991)")
    private let categoryField = DriverLicenseEditViewController.makeField(placeholder: "Категорії (напр. B, C)")
    private let numberField = DriverLicenseEditViewController.makeField(placeholder: "Номер посвідчення")
    private let validUntilField = DriverLicenseEditViewController.makeField(placeholder: "Дійсне до (напр. 20.05.2024)")

    private lazy var textFields: [UITextField] = [
        fullNameField, birthDateField, categoryField, numberField, validUntilField
    ]

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Зберегти", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Посвідчення водія"
        view.backgroundColor = .systemBackground
        setupLayout()
        loadCurrentValues()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)
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
    }

    private func loadCurrentValues() {
        let fields = DriverLicenseStorage.shared.snapshot()
        fullNameField.text = fields.fullName
        birthDateField.text = fields.birthDate
        categoryField.text = fields.category
        numberField.text = fields.number
        validUntilField.text = fields.validUntil
        updatePhotoButton()
    }

    private func updatePhotoButton() {
        if let photo = DriverLicenseStorage.shared.photo {
            photoButton.setImage(photo, for: .normal)
            photoButton.setTitle(nil, for: .normal)
        } else {
            photoButton.setImage(nil, for: .normal)
            photoButton.setTitle("Додати фото", for: .normal)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func photoTapped() {
        let sheet = UIAlertController(title: "Фото на документ", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Камера", style: .default) { [weak self] _ in
            self?.presentPicker(source: .camera)
        })
        sheet.addAction(UIAlertAction(title: "Галерея", style: .default) { [weak self] _ in
            self?.presentPicker(source: .photoLibrary)
        })
        if DriverLicenseStorage.shared.photo != nil {
            sheet.addAction(UIAlertAction(title: "Видалити фото", style: .destructive) { [weak self] _ in
                DriverLicenseStorage.shared.clearPhoto()
                self?.updatePhotoButton()
                DriverLicenseSeeder.sync()
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        // iPad needs an anchor for the popover presentation.
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

    @objc private func saveTapped() {
        DriverLicenseStorage.shared.apply(
            .init(
                fullName: fullNameField.text ?? "",
                birthDate: birthDateField.text ?? "",
                category: categoryField.text ?? "",
                number: numberField.text ?? "",
                issuedBy: DriverLicenseStorage.shared.issuedBy,
                validUntil: validUntilField.text ?? ""
            )
        )
        // Refresh the stored document immediately so the Documents tab
        // shows the new values without needing an app restart.
        DriverLicenseSeeder.sync()
        navigationController?.popViewController(animated: true)
    }

    private static func makeField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 16)
        field.returnKeyType = .next
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }
}

extension DriverLicenseEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = textFields.firstIndex(of: textField) else {
            textField.resignFirstResponder()
            return true
        }
        if index + 1 < textFields.count {
            textFields[index + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension DriverLicenseEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else { return }
        DriverLicenseStorage.shared.savePhoto(image)
        updatePhotoButton()
        DriverLicenseSeeder.sync()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
