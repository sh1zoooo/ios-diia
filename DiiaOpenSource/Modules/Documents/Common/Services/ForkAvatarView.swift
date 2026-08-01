import UIKit

/// FORK: photo picker box for document edit forms.
///
/// Deliberately simple: a slightly-rounded 1:1 SQUARE (not a circle). An
/// earlier circular version could render as a lens/eye shape whenever Auto
/// Layout ever resolved a non-square frame, because cornerRadius = width/2
/// on a non-square view produces a stadium/lens shape, not a circle. A
/// small fixed corner radius on a square avoids that failure mode entirely —
/// even if the frame is ever slightly off-square, it still just looks like a
/// rounded rectangle, never an eye.
///
/// Square-ness is enforced structurally via `heightAnchor.constraint(equalTo:
/// widthAnchor)`, not just two independent constants — so even if a parent
/// stack view stretches the width, the height always follows it 1:1.
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
        l.font = .systemFont(ofSize: 32, weight: .light)
        l.textColor = UIColor(white: 0.40, alpha: 1.0)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let badgeButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .black
        b.tintColor = .white
        b.clipsToBounds = true
        b.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// Small, fixed corner radius — a "slightly rounded square" look, same
    /// idea as e.g. an app icon, regardless of the view's actual size.
    private let cornerRadiusValue: CGFloat = 16

    private var viewModel: ViewModel

    public init(viewModel: ViewModel, side: CGFloat = 110) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews(side: side)
        applyViewModel()
        badgeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews(side: CGFloat) {
        layer.cornerRadius = cornerRadiusValue
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        clipsToBounds = true
        backgroundColor = UIColor(white: 0.92, alpha: 1.0)

        addSubview(imageView)
        addSubview(placeholderLabel)
        addSubview(badgeButton)

        NSLayoutConstraint.activate([
            // Fixed width, and height is FORCED to equal width — this is what
            // guarantees a true 1:1 square no matter what a parent stack view
            // does, unlike two independent constant constraints.
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalTo: widthAnchor),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Camera badge: small circle, fully INSIDE bounds (not overhanging
            // past the edge — the container clips to bounds, so anything
            // outside would just get its edges cut off).
            badgeButton.widthAnchor.constraint(equalToConstant: 32),
            badgeButton.heightAnchor.constraint(equalToConstant: 32),
            badgeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            badgeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Fixed radius, NOT proportional to bounds — this is the key
        // difference from the old circular version. A constant radius always
        // reads as "rounded square", even in the rare case the frame ends up
        // very slightly non-square.
        layer.cornerRadius = cornerRadiusValue
        badgeButton.layer.cornerRadius = badgeButton.bounds.width / 2
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
