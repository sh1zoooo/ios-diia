import UIKit

/// FORK: birth-certificate edit form, redesigned in Diia style via ForkEditFormBuilder.
final class BirthCertificateEditViewController: UIViewController {

    private var surname: String = ""
    private var firstName: String = ""
    private var middleName: String = ""
    private var birthDate: String = ""
    private var birthPlace: String = ""
    private var recordNumber: String = ""
    private var issuedBy: String = ""
    private var issuedDate: String = ""

    private var textFields: [UITextField] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Актовий запис"
        loadCurrentValues()
        buildForm()
    }

    private func buildForm() {
        let result = ForkEditFormBuilder.build(
            in: self,
            title: "Актовий запис про народження",
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
                    .text(icon: UIImage(systemName: "mappin.and.ellipse"),
                         label: "МІСЦЕ НАРОДЖЕННЯ",
                         placeholder: "напр. м. Київ",
                         value: birthPlace,
                         keyboardType: .default,
                         returnKey: .next,
                         onChange: { [weak self] v in self?.birthPlace = v }),
                    .text(icon: UIImage(systemName: "number"),
                         label: "НОМЕР АКТОВОГО ЗАПИСУ",
                         placeholder: "напр. 1234",
                         value: recordNumber,
                         keyboardType: .numbersAndPunctuation,
                         returnKey: .done,
                         onChange: { [weak self] v in self?.recordNumber = v }),
                ]),
            ],
            avatar: nil,
            primaryButton: .init(title: "Зберегти", style: .primary, action: { [weak self] in self?.saveTapped() }),
            secondaryButton: .init(title: "Скасувати", style: .secondary, action: { [weak self] in self?.cancelTapped() }),
            backAction: { [weak self] in self?.cancelTapped() }
        )
        self.textFields = result.textFields
        textFields.enumerated().forEach { idx, tf in
            tf.delegate = self
            tf.tag = idx
        }
    }

    private func loadCurrentValues() {
        let s = BirthCertificateStorage.shared.snapshot()
        surname = s.surname
        firstName = s.firstName
        middleName = s.middleName
        birthDate = s.birthDate
        birthPlace = s.birthPlace
        recordNumber = s.recordNumber
        issuedBy = s.issuedBy
        issuedDate = s.issuedDate
    }

    @objc private func saveTapped() {
        BirthCertificateStorage.shared.apply(
            .init(surname: surname,
                  firstName: firstName,
                  middleName: middleName,
                  birthDate: birthDate,
                  birthPlace: birthPlace,
                  recordNumber: recordNumber,
                  issuedBy: issuedBy,
                  issuedDate: issuedDate)
        )
        BirthCertificateSeeder.sync()
        navigationController?.popViewController(animated: true)
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension BirthCertificateEditViewController: UITextFieldDelegate {
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
