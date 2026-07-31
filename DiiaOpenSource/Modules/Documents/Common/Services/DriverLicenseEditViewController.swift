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

    private let fullNameField = DriverLicenseEditViewController.makeField(placeholder: "Прізвище, ім'я, по батькові")
    private let birthDateField = DriverLicenseEditViewController.makeField(placeholder: "Дата народження (напр. 24.08.1991)")
    private let categoryField = DriverLicenseEditViewController.makeField(placeholder: "Категорії (напр. B, C)")
    private let numberField = DriverLicenseEditViewController.makeField(placeholder: "Номер посвідчення")
    private let issuedByField = DriverLicenseEditViewController.makeField(placeholder: "Видав (напр. ТСЦ 0000)")
    private let validUntilField = DriverLicenseEditViewController.makeField(placeholder: "Дійсне до (напр. 20.05.2024)")

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

        [fullNameField, birthDateField, categoryField, numberField, issuedByField, validUntilField]
            .forEach { stackView.addArrangedSubview($0) }
    }

    private func loadCurrentValues() {
        let fields = DriverLicenseStorage.shared.snapshot()
        fullNameField.text = fields.fullName
        birthDateField.text = fields.birthDate
        categoryField.text = fields.category
        numberField.text = fields.number
        issuedByField.text = fields.issuedBy
        validUntilField.text = fields.validUntil
    }

    @objc private func saveTapped() {
        DriverLicenseStorage.shared.apply(
            .init(
                fullName: fullNameField.text ?? "",
                birthDate: birthDateField.text ?? "",
                category: categoryField.text ?? "",
                number: numberField.text ?? "",
                issuedBy: issuedByField.text ?? "",
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
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }
}
