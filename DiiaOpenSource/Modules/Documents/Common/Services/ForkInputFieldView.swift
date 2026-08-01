import UIKit

/// FORK: custom input field view in Diia style.
///
/// Layout:
/// ┌─────────────────────────────┐
/// │ 👤  LABEL (uppercase grey)  │
/// │    Input value text          │
/// └─────────────────────────────┘
///
/// White background, no border. Optional icon on the left (24×24).
/// Optional separator below (1pt blackAlpha).
public final class ForkInputFieldView: UIView {

    public struct ViewModel {
        public var icon: UIImage?
        public var label: String
        public var placeholder: String
        public var value: String
        public var keyboardType: UIKeyboardType
        public var returnKeyType: UIReturnKeyType
        public var onChange: (String) -> Void

        public init(icon: UIImage? = nil,
                    label: String,
                    placeholder: String = "",
                    value: String = "",
                    keyboardType: UIKeyboardType = .default,
                    returnKeyType: UIReturnKeyType = .default,
                    onChange: @escaping (String) -> Void = { _ in }) {
            self.icon = icon
            self.label = label
            self.placeholder = placeholder
            self.value = value
            self.keyboardType = keyboardType
            self.returnKeyType = returnKeyType
            self.onChange = onChange
        }
    }

    // MARK: - Subviews
    private let iconImageView = UIImageView()
    private let labelLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor(white: 0.55, alpha: 1.0)
        l.numberOfLines = 1
        l.textAlignment = .left
        return l
    }()
    private let textField: UITextField = {
        let f = UITextField()
        f.font = .systemFont(ofSize: 17, weight: .regular)
        f.textColor = .black
        f.borderStyle = .none
        f.backgroundColor = .clear
        f.adjustsFontSizeToFitWidth = false
        // Make placeholder darker than default — on the gradient background
        // the system placeholderTextColor (~0.5 alpha gray) is barely visible.
        // Use ~0.45 black which renders visibly even on a colored gradient.
        f.attributedPlaceholder = nil
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    private let separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - State
    private var viewModel: ViewModel
    public var textFieldDelegate: UITextFieldDelegate? {
        get { textField.delegate }
        set { textField.delegate = newValue }
    }

    /// Optional: caller can set this to expose the underlying textfield
    /// (e.g. for becomeFirstResponder cycling between fields).
    public var innerTextField: UITextField { textField }

    // MARK: - Init
    public init(viewModel: ViewModel, showsSeparator: Bool = true) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupSubviews(showsSeparator: showsSeparator)
        applyViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupSubviews(showsSeparator: Bool) {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(white: 0.20, alpha: 1.0)
        addSubview(iconImageView)

        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelLabel)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        addSubview(textField)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.isHidden = !showsSeparator
        addSubview(separatorView)

        // Icon size: 24×24, vertically centered.
        // If icon is nil, hide the image view and let content start at leading 16.
        let iconVisible = viewModel.icon != nil

        NSLayoutConstraint.activate([
            // Row height: 64pt minimum, expandable.
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

            // Icon
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: iconVisible ? 16 : 0),

            // Label
            labelLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            labelLabel.leadingAnchor.constraint(equalTo: iconVisible ? iconImageView.trailingAnchor : leadingAnchor, constant: iconVisible ? 12 : 16),
            labelLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Text field
            textField.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: labelLabel.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            // Separator
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
        ])

        iconImageView.isHidden = !iconVisible
        iconImageView.image = viewModel.icon?.withRenderingMode(.alwaysTemplate)
    }

    private func applyViewModel() {
        labelLabel.text = viewModel.label
        textField.text = viewModel.value
        // Darker placeholder so it's readable on the animated gradient bg.
        // UIColor(white: 0.20, alpha: 0.55) is much darker than the system
        // default (~0.5 alpha gray).
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.20, alpha: 0.55),
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
        ]
        textField.attributedPlaceholder = NSAttributedString(
            string: viewModel.placeholder,
            attributes: placeholderAttrs
        )
        textField.keyboardType = viewModel.keyboardType
        textField.returnKeyType = viewModel.returnKeyType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
    }

    @objc private func textChanged() {
        let v = textField.text ?? ""
        viewModel.value = v
        viewModel.onChange(v)
    }

    /// Force-update from outside (e.g. after editing the storage).
    public func update(value: String) {
        viewModel.value = value
        textField.text = value
    }
}
