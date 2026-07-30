import UIKit
import DiiaMVPModule
import DiiaUIComponents

protocol ProfileView: BaseView {
    func display(snapshot: ProfileStorage.Snapshot)
    func display(photo: UIImage?)
    func showPhotoSourcePicker()
}

extension ProfileViewController: Storyboarded {}

final class ProfileViewController: UIViewController, ProfileView {

    var presenter: ProfileAction!

    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var backButton: UIButton!

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var changePhotoButton: UIButton!
    @IBOutlet private weak var removePhotoButton: UIButton!

    @IBOutlet private weak var firstNameField:  UITextField!
    @IBOutlet private weak var lastNameField:   UITextField!
    @IBOutlet private weak var middleNameField: UITextField!
    @IBOutlet private weak var birthDateField:  UITextField!
    @IBOutlet private weak var cityField:       UITextField!
    @IBOutlet private weak var phoneField:      UITextField!
    @IBOutlet private weak var emailField:      UITextField!
    @IBOutlet private weak var aboutTextView:   UITextView!
    @IBOutlet private weak var aboutPlaceholderLabel: UILabel!

    @IBOutlet private weak var clearAllButton: UIButton!

    // MARK: - Private
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale.current
        return f
    }()

    private lazy var birthDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()
        picker.addTarget(self, action: #selector(birthDateChanged(_:)), for: .valueChanged)
        return picker
    }()

    private lazy var photoPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()

    private lazy var photoSourceAlert: UIAlertController = {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(.init(title: "Камера", style: .default) { [weak self] _ in
                self?.presentPhotoPicker(source: .camera)
            })
        }
        alert.addAction(.init(title: "Галерея", style: .default) { [weak self] _ in
            self?.presentPhotoPicker(source: .photoLibrary)
        })
        alert.addAction(.init(title: "Скасувати", style: .cancel))
        return alert
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        presenter.onViewDidLoad()
    }

    private func initialSetup() {
        titleLabel.font = FontBook.smallHeadingFont
        titleLabel.text = "Профіль"

        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        avatarImageView.image = placeholderAvatar()

        changePhotoButton.titleLabel?.font = FontBook.bigText
        removePhotoButton.titleLabel?.font = FontBook.bigText

        [firstNameField, lastNameField, middleNameField,
         cityField, phoneField, emailField].forEach {
            $0.delegate = self
            $0.font = FontBook.bigText
            $0.borderStyle = .roundedRect
        }

        birthDateField.inputView = birthDatePicker
        birthDateField.delegate = self
        birthDateField.font = FontBook.bigText
        birthDateField.borderStyle = .roundedRect

        aboutTextView.delegate = self
        aboutTextView.font = FontBook.bigText
        aboutTextView.layer.cornerRadius = 6
        aboutTextView.layer.borderWidth = 1
        aboutTextView.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor

        // Toolbar with "Done" for date picker
        let toolbar = UIToolbar()
        toolbar.items = [
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            .init(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        ]
        toolbar.sizeToFit()
        birthDateField.inputAccessoryView = toolbar
    }

    private func placeholderAvatar() -> UIImage? {
        let size = avatarImageView.bounds.size
        guard size.width > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(white: 0.85, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.4, weight: .light),
                .foregroundColor: UIColor.darkGray
            ]
            let str = "А" as NSString
            let sizeStr = str.size(withAttributes: attrs)
            str.draw(at: CGPoint(x: (size.width - sizeStr.width) / 2,
                                  y: (size.height - sizeStr.height) / 2),
                     withAttributes: attrs)
        }
    }

    // MARK: - Actions
    @IBAction private func backTapped() {
        presenter.onBackTapped()
    }

    @IBAction private func changePhotoTapped() {
        presenter.onChangePhotoTapped()
    }

    @IBAction private func removePhotoTapped() {
        presenter.onRemovePhotoTapped()
    }

    @IBAction private func clearAllTapped() {
        let alert = UIAlertController(title: "Очистити профіль?",
                                       message: "Усі введені дані буде видалено.",
                                       preferredStyle: .alert)
        alert.addAction(.init(title: "Скасувати", style: .cancel))
        alert.addAction(.init(title: "Очистити", style: .destructive) { [weak self] _ in
            self?.presenter.onClearAllTapped()
        })
        present(alert, animated: true)
    }

    @objc private func birthDateChanged(_ picker: UIDatePicker) {
        birthDateField.text = dateFormatter.string(from: picker.date)
        presenter.onBirthDateChanged(picker.date)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func presentPhotoPicker(source: UIImagePickerController.SourceType) {
        photoPicker.sourceType = source
        present(photoPicker, animated: true)
    }

    // MARK: - ProfileView
    func showPhotoSourcePicker() {
        present(photoSourceAlert, animated: true)
    }

    func display(snapshot: ProfileStorage.Snapshot) {
        firstNameField.text  = snapshot.firstName
        lastNameField.text   = snapshot.lastName
        middleNameField.text = snapshot.middleName
        cityField.text       = snapshot.city
        phoneField.text      = snapshot.phone
        emailField.text      = snapshot.email
        aboutTextView.text   = snapshot.about
        aboutPlaceholderLabel.isHidden = !snapshot.about.isEmpty

        if let date = snapshot.birthDate {
            birthDateField.text = dateFormatter.string(from: date)
            birthDatePicker.date = date
        } else {
            birthDateField.text = ""
            birthDatePicker.date = Date()
        }

        display(photo: snapshot.photo)
    }

    func display(photo: UIImage?) {
        if let photo = photo {
            avatarImageView.image = photo
        } else {
            avatarImageView.image = placeholderAvatar()
        }
    }
}

// MARK: - UITextFieldDelegate
extension ProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = (textField.text ?? "") as NSString
        let updated = current.replacingCharacters(in: range, with: string)
        let field: ProfileField
        switch textField {
        case firstNameField:  field = .firstName
        case lastNameField:   field = .lastName
        case middleNameField: field = .middleName
        case cityField:       field = .city
        case phoneField:      field = .phone
        case emailField:      field = .email
        default: return true
        }
        presenter.onFieldChanged(field, value: updated)
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension ProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        aboutPlaceholderLabel.isHidden = !textView.text.isEmpty
        presenter.onFieldChanged(.about, value: textView.text)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let image = image {
            // Square crop to keep the avatar circle tidy
            let squared = image.squared()
            ProfileStorage.shared.savePhoto(squared)
            display(photo: squared)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIImage square helper
private extension UIImage {
    func squared() -> UIImage {
        let side = min(size.width, size.height)
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2
        let cropRect = CGRect(x: originX, y: originY, width: side, height: side)
        guard let cgImage = cgImage?.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}
