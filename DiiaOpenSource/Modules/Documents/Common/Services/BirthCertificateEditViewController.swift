import UIKit

/// FORK: simple form for the birth-certificate fields. Mirrors PassportEditViewController.
final class BirthCertificateEditViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        return s
    }()

    private let surnameField      = BirthCertificateEditViewController.makeField(placeholder: "Прізвище")
    private let firstNameField    = BirthCertificateEditViewController.makeField(placeholder: "Ім’я")
    private let middleNameField   = BirthCertificateEditViewController.makeField(placeholder: "По батькові")
    private let birthDateField    = BirthCertificateEditViewController.makeField(placeholder: "Дата народження (напр. 24.08.1991)")
    private let birthPlaceField   = BirthCertificateEditViewController.makeField(placeholder: "Місце народження")
    private let recordNumberField = BirthCertificateEditViewController.makeField(placeholder: "Номер актового запису")
    private let issuedByField     = BirthCertificateEditViewController.makeField(placeholder: "Орган реєстрації (ЗАГС)")
    private let issuedDateField   = BirthCertificateEditViewController.makeField(placeholder: "Дата реєстрації")

    private lazy var textFields: [UITextField] = [
        surnameField, firstNameField, middleNameField, birthDateField,
        birthPlaceField, recordNumberField, issuedByField, issuedDateField
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
        title = "Актовий запис про народження"
        view.backgroundColor = .systemBackground
        setupLayout()
        loadCurrentValues()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        textFields.forEach { $0.delegate = self }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false

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

        textFields.forEach { stackView.addArrangedSubview($0) }
    }

    private func loadCurrentValues() {
        let s = BirthCertificateStorage.shared.snapshot()
        surnameField.text      = s.surname
        firstNameField.text    = s.firstName
        middleNameField.text   = s.middleName
        birthDateField.text    = s.birthDate
        birthPlaceField.text   = s.birthPlace
        recordNumberField.text = s.recordNumber
        issuedByField.text     = s.issuedBy
        issuedDateField.text   = s.issuedDate
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func saveTapped() {
        BirthCertificateStorage.shared.apply(
            .init(surname: surnameField.text ?? "",
                  firstName: firstNameField.text ?? "",
                  middleName: middleNameField.text ?? "",
                  birthDate: birthDateField.text ?? "",
                  birthPlace: birthPlaceField.text ?? "",
                  recordNumber: recordNumberField.text ?? "",
                  issuedBy: issuedByField.text ?? "",
                  issuedDate: issuedDateField.text ?? "")
        )
        BirthCertificateSeeder.sync()
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

extension BirthCertificateEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let i = textFields.firstIndex(of: textField) else { textField.resignFirstResponder(); return true }
        if i + 1 < textFields.count { textFields[i + 1].becomeFirstResponder() } else { textField.resignFirstResponder() }
        return true
    }
}
