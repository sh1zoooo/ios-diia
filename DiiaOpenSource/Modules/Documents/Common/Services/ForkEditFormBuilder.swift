import UIKit
import Lottie

/// FORK: universal form builder that lays out a Diia-styled edit screen.
///
/// Composition:
///   - LottieAnimationView "background_gradient" filling the whole view (animated
///     gradient that matches the Documents tab background)
///   - TopNavigationBigView at the top with back button
///   - UIScrollView + UIStackView with sections of white rounded cards
///   - Optional avatar above the cards (centered, with camera badge)
///   - Primary + optional secondary buttons pinned to the bottom
///
/// Each section is a white card with cornerRadius 16, containing a list of
/// ForkInputFieldView rows separated by thin grey lines. Sections are separated
/// by 12pt vertical gaps. An optional section title (uppercase grey) sits above
/// each card.
public final class ForkEditFormBuilder {

    public struct Section {
        public let title: String?
        public let fields: [Field]
        public init(title: String? = nil, fields: [Field]) {
            self.title = title
            self.fields = fields
        }
    }

    public enum Field {
        /// Text input row with icon + uppercase label + value.
        case text(icon: UIImage?, label: String, placeholder: String,
                  value: String, keyboardType: UIKeyboardType,
                  returnKey: UIReturnKeyType, onChange: (String) -> Void)
        /// Read-only row that opens something on tap (e.g. "Намалювати підпис").
        case buttonRow(icon: UIImage?, label: String, onTap: () -> Void)
    }

    public struct Button {
        public let title: String
        public let style: ForkFormButtonView.Style
        public let action: () -> Void
        public init(title: String, style: ForkFormButtonView.Style, action: @escaping () -> Void) {
            self.title = title
            self.style = style
            self.action = action
        }
    }

    public struct Avatar {
        public let image: UIImage?
        public let placeholderInitial: String
        public let onTap: () -> Void
        public init(image: UIImage?, placeholderInitial: String, onTap: @escaping () -> Void) {
            self.image = image
            self.placeholderInitial = placeholderInitial
            self.onTap = onTap
        }
    }

    // MARK: - Build

    /// Builds the entire form inside `viewController.view`.
    /// Returns a tuple of (textFieldRefs, avatarViewRef) so the caller can
    /// drive "Next" return-key cycling and update the avatar after picking.
    @discardableResult
    public static func build(
        in viewController: UIViewController,
        title: String,
        subtitle: String? = nil,
        sections: [Section],
        avatar: Avatar? = nil,
        primaryButton: Button? = nil,
        secondaryButton: Button? = nil,
        backAction: @escaping () -> Void
    ) -> (textFields: [UITextField], avatarView: ForkAvatarView?) {

        let view = viewController.view!
        view.backgroundColor = .white

        // 1. Animated gradient background (Lottie, same as Documents tab).
        let bg = LottieAnimationView(name: "background_gradient")
        bg.contentMode = .scaleAspectFill
        bg.loopMode = .loop
        bg.backgroundBehavior = .pauseAndRestore
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.isUserInteractionEnabled = false
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        bg.play()

        // 2. (Back button removed — we rely on the system navigation bar
        //     that the host UINavigationController already provides.)

        // 3. Title label.
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.text = title
        view.addSubview(titleLabel)

        // 4. Subtitle label (optional).
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.40, alpha: 1.0)
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        view.addSubview(subtitleLabel)

        // 5. Scroll view + content stack.
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // 6. Buttons (pinned to bottom of view, above safe area).
        let buttonsStack = UIStackView()
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 8
        buttonsStack.alignment = .fill
        buttonsStack.distribution = .fill
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStack)

        // Layout constraints for top + scroll + buttons
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonsStack.topAnchor, constant: -8),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])

        // 7. Optional avatar (above the cards, centered).
        var avatarViewRef: ForkAvatarView? = nil
        if let avatar = avatar {
            let av = ForkAvatarView(viewModel: .init(
                image: avatar.image,
                placeholderInitial: avatar.placeholderInitial,
                onTap: avatar.onTap
            ))
            av.translatesAutoresizingMaskIntoConstraints = false
            let wrapper = UIStackView(arrangedSubviews: [av])
            wrapper.axis = .horizontal
            wrapper.alignment = .center
            wrapper.distribution = .equalCentering
            contentStack.addArrangedSubview(wrapper)
            avatarViewRef = av
        }

        // 8. Sections (each = optional title label + white card with rows).
        var textFields: [UITextField] = []
        for section in sections {
            // Section title
            if let title = section.title {
                let l = UILabel()
                l.text = title.uppercased()
                l.font = .systemFont(ofSize: 11, weight: .semibold)
                l.textColor = UIColor(white: 0.40, alpha: 1.0)
                l.translatesAutoresizingMaskIntoConstraints = false
                l.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
                contentStack.setCustomSpacing(4, after: l)
                // Wrap in a horizontal stack with leading/trailing padding so the
                // label stays left-aligned within the content stack.
                let wrapper = UIStackView(arrangedSubviews: [l])
                wrapper.axis = .horizontal
                wrapper.alignment = .leading
                wrapper.isLayoutMarginsRelativeArrangement = true
                wrapper.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16)
                contentStack.addArrangedSubview(wrapper)
            }

            // White card
            let card = UIView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.backgroundColor = .white
            card.layer.cornerRadius = 16
            card.layer.masksToBounds = false
            // Soft shadow
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.05
            card.layer.shadowOffset = CGSize(width: 0, height: 2)
            card.layer.shadowRadius = 8

            let cardStack = UIStackView()
            cardStack.axis = .vertical
            cardStack.spacing = 0
            cardStack.alignment = .fill
            cardStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(cardStack)
            NSLayoutConstraint.activate([
                cardStack.topAnchor.constraint(equalTo: card.topAnchor),
                cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
                cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            ])

            for (idx, field) in section.fields.enumerated() {
                let showsSep = idx < section.fields.count - 1
                switch field {
                case let .text(icon, label, placeholder, value, kbType, returnKey, onChange):
                    let fieldView = ForkInputFieldView(
                        viewModel: .init(
                            icon: icon,
                            label: label,
                            placeholder: placeholder,
                            value: value,
                            keyboardType: kbType,
                            returnKeyType: returnKey,
                            onChange: onChange
                        ),
                        showsSeparator: showsSep
                    )
                    cardStack.addArrangedSubview(fieldView)
                    textFields.append(fieldView.innerTextField)
                case let .buttonRow(icon, label, onTap):
                    let row = makeButtonRow(icon: icon, label: label, onTap: onTap, showsSeparator: showsSep)
                    cardStack.addArrangedSubview(row)
                }
            }

            contentStack.addArrangedSubview(card)
        }

        // 9. Bottom buttons.
        if let primary = primaryButton {
            let b = ForkFormButtonView(title: primary.title, style: primary.style, onTap: primary.action)
            buttonsStack.addArrangedSubview(b)
        }
        if let secondary = secondaryButton {
            let b = ForkFormButtonView(title: secondary.title, style: secondary.style, onTap: secondary.action)
            buttonsStack.addArrangedSubview(b)
        }
        if primaryButton == nil && secondaryButton == nil {
            // Reserve a tiny spacer so scroll bottom inset doesn't collapse.
            buttonsStack.addArrangedSubview(UIView())
        }

        // 10. Tap anywhere to dismiss keyboard.
        //     Use a small NSObject host so we don't have to add an @objc
        //     instance method to the viewController (which would require
        //     subclassing or runtime swizzling).
        let dismissHost = ForkEditFormHost(backAction: backAction, viewController: viewController)
        forkAttachHost(to: viewController, host: dismissHost)

        let tap = UITapGestureRecognizer(target: dismissHost, action: #selector(ForkEditFormHost.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        return (textFields, avatarViewRef)
    }

    // MARK: - Helpers
    private static func makeButtonRow(icon: UIImage?, label: String, onTap: @escaping () -> Void, showsSeparator: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear

        let iconView = UIImageView(image: icon?.withRenderingMode(.alwaysTemplate))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(white: 0.20, alpha: 1.0)
        iconView.isHidden = icon == nil
        container.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.text = label
        container.addSubview(titleLabel)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = UIColor(white: 0.60, alpha: 1.0)
        chevron.contentMode = .scaleAspectFit
        container.addSubview(chevron)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        separator.isHidden = !showsSeparator
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: icon == nil ? container.leadingAnchor : iconView.trailingAnchor, constant: icon == nil ? 16 : 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])

        let tap = UITapGestureRecognizer(target: ButtonRowActionContainer.shared, action: #selector(ButtonRowActionContainer.fire(_:)))
        tap.cancelsTouchesInView = false
        ButtonRowActionContainer.shared.register(container, action: onTap)
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        return container
    }
}

// MARK: - Host helpers
//
// We need a stable NSObject target whose @objc instance methods can be used as
// selectors from UIButton / UITapGestureRecognizer. The view controller itself
// can't host those methods because Swift @objc instance methods can't be added
// to a class via extension across module boundaries — and even within the same
// module, `addTarget(vc, action: #selector(SomeClass.method))` requires the
// method to be visible on the vc instance, which only works if SomeClass IS
// the vc's class.
//
// Solution: a small NSObject "action-target" that holds a closure. Each
// builder invocation creates one and stores it via associated object on the
// view controller (so it lives as long as the vc does).

private final class ForkEditFormHost: NSObject {
    let backAction: () -> Void
    weak var viewController: UIViewController?

    init(backAction: @escaping () -> Void, viewController: UIViewController) {
        self.backAction = backAction
        self.viewController = viewController
        super.init()
    }

    @objc func backTapped() {
        backAction()
    }

    @objc func dismissKeyboard() {
        viewController?.view.endEditing(true)
    }
}

private var forkHostKey: UInt8 = 0

private func forkAttachHost(to vc: UIViewController, host: ForkEditFormHost) {
    objc_setAssociatedObject(vc, &forkHostKey, host, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

private func forkHost(for vc: UIViewController) -> ForkEditFormHost? {
    objc_getAssociatedObject(vc, &forkHostKey) as? ForkEditFormHost
}

// We need to bridge button-row taps to per-instance closures. Use a small
// singleton registry keyed by view pointer.
private final class ButtonRowActionContainer {
    static let shared = ButtonRowActionContainer()
    private var registry: [ObjectIdentifier: () -> Void] = [:]

    func register(_ view: UIView, action: @escaping () -> Void) {
        registry[ObjectIdentifier(view)] = action
    }

    @objc func fire(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        registry[ObjectIdentifier(view)]?()
    }
}
