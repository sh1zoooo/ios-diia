import UIKit

/// FORK: circular avatar view with a "camera" badge in the bottom-right corner.
/// Used by the document edit forms to let the user pick / replace the photo.
public final class ForkAvatarView: UIView {

    public struct ViewModel {
        public var image: UIImage?
        public var placeholderInitial: String   // single letter shown when no photo
        public var onTap: () -> Void

        public init(image: UIImage?,
                    placeholderInitial: String = "?",
                    onTap: @escaping () -> Void) {
            self.image = image
            self.placeholderInitial = placeholderInitial
            self.onTap = onTap
        }
    }

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .light)
        l.textColor = UIColor(white: 0.40, alpha: 1.0)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let badgeButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .black
        b.tintColor = .white
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private var viewModel: ViewModel

    public init(viewModel: ViewModel, diameter: CGFloat = 100) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews(diameter: diameter)
        applyViewModel()
        badgeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        // The whole avatar is also tappable.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews(diameter: CGFloat) {
        // Container view IS the avatar. Width = Height = diameter.
        layer.cornerRadius = diameter / 2
        layer.borderWidth = 3
        layer.borderColor = UIColor.white.cgColor
        clipsToBounds = true
        backgroundColor = UIColor(white: 0.92, alpha: 1.0)

        addSubview(imageView)
        addSubview(placeholderLabel)
        addSubview(badgeButton)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Camera badge: 36×36 circle, bottom-right corner, slightly outside.
            badgeButton.widthAnchor.constraint(equalToConstant: 36),
            badgeButton.heightAnchor.constraint(equalToConstant: 36),
            badgeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 4),
            badgeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
        ])
    }

    private func applyViewModel() {
        if let image = viewModel.image {
            imageView.image = image
            imageView.isHidden = false
            placeholderLabel.isHidden = true
        } else {
            imageView.image = nil
            imageView.isHidden = true
            placeholderLabel.isHidden = false
            placeholderLabel.text = viewModel.placeholderInitial
        }
    }

    @objc private func tapped() {
        viewModel.onTap()
    }

    /// Update the avatar image from outside (e.g. after UIImagePickerController).
    public func update(image: UIImage?) {
        viewModel.image = image
        applyViewModel()
    }
}
