import UIKit

/// FORK: stylized button in Diia style.
///
/// Styles:
/// - .primary     → black background, white text, cornerRadius 12, bold 17pt
/// - .secondary   → transparent, black 1pt border, black text, medium 16pt
/// - .destructive → red background, white text (used for "Clear all data")
public final class ForkFormButtonView: UIControl {

    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let style: Style
    private let onTap: () -> Void

    public init(title: String, style: Style, onTap: @escaping () -> Void) {
        self.style = style
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 12
        layer.borderWidth = 0
        clipsToBounds = true
        setupSubviews()
        applyStyle()
        titleLabel.text = title
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
    }

    private func applyStyle() {
        switch style {
        case .primary:
            backgroundColor = .black
            titleLabel.textColor = .white
        case .secondary:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.black.cgColor
            titleLabel.textColor = .black
            titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        case .destructive:
            backgroundColor = UIColor(red: 0.86, green: 0.21, blue: 0.18, alpha: 1.0)
            titleLabel.textColor = .white
        }
    }

    @objc private func tapped() {
        onTap()
    }
}
