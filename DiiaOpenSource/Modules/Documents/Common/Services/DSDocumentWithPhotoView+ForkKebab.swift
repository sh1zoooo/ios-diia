import UIKit
import DiiaUIComponents
import DiiaDocumentsCommonTypes

/// FORK: extension that adds a black circular "⋯" (kebab) button to
/// `DSDocumentWithPhotoView` after it's been laid out, positioned next to
/// the bottomHeading's full-name area — matching the original Diia card.
///
/// Also bumps the bottomHeading font sizes a bit larger than the original
/// Diia defaults, because the user wanted the bottom full-name a touch bigger.
///
/// Why an overlay instead of using `DSDocumentHeading.iconAtm`?
///   `DSDocumentHeadingView` looks up the kebab icon via
///   `UIComponentsConfiguration.shared.imageProvider.imageForCode(...)` which
///   uses `Bundle.module` (the DiiaUIComponents SPM bundle). Our local asset
///   catalog is NOT visible there, so `iconAtm` would render an empty button.
///   Rather than fork the SPM package, we just overlay our own UIButton
///   via `layoutSubviews` swizzling on `DSDocumentWithPhotoView`.
///
/// Implementation note:
///   `DSDocumentWithPhotoView` is a `final public class` (cannot subclass),
///   so we hook into `layoutSubviews` via the Objective-C runtime. The
///   swizzle is installed once on app launch (see `forkInstallKebabSwizzle()`).
extension DSDocumentWithPhotoView {

    private static var kebabKey: UInt8 = 0
    private static var kebabHandlerKey: UInt8 = 0
    private static var bottomHeadingEnlargedKey: UInt8 = 0

    /// Idempotent installer — call once at app launch (e.g. from
    /// `AppConfigurator.configureApp()`).
    static func forkInstallKebabSwizzle() {
        // Swap layoutSubviews so we can add the kebab button after every layout.
        let originalSelector = #selector(layoutSubviews)
        let swizzledSelector = #selector(forkLayoutSubviews)
        guard
            let originalMethod = class_getInstanceMethod(DSDocumentWithPhotoView.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(DSDocumentWithPhotoView.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private func forkLayoutSubviews() {
        // Call original (after exchange, this points to the original IMP).
        self.forkLayoutSubviews()

        // Make sure the kebab button is present.
        forkEnsureKebabButton()
        // Bump font sizes of the bottomHeading subviews once.
        forkEnlargeBottomHeadingFonts()
    }

    private func forkEnsureKebabButton() {
        if let existing = objc_getAssociatedObject(self, &Self.kebabKey) as? UIButton {
            // Make sure it stays on top after re-layout.
            self.bringSubviewToFront(existing)
            return
        }

        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setTitle("⋯", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(forkKebabTapped), for: .touchUpInside)

        addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        objc_setAssociatedObject(self, &Self.kebabKey, button, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // Wire the kebab to the existing contextMenuCallback (if any). This
        // opens the same action sheet the original Diia card shows.
        forkKebabHandler = { [weak self] in
            self?.contextMenuCallback?()
        }
    }

    /// Walks the subview tree of `self` and bumps the font of every `UILabel`
    /// found inside the bottom `DSDocumentHeadingView` (the one anchored to
    /// bottomAnchor). Idempotent.
    private func forkEnlargeBottomHeadingFonts() {
        if objc_getAssociatedObject(self, &Self.bottomHeadingEnlargedKey) as? Bool == true {
            return
        }
        // Find any DSDocumentHeadingView in the subview tree — DSDocumentWithPhotoView
        // contains exactly two: the top docHeadingView (heading "Паспорт громадянина...")
        // and the bottom docBottomView (full name). We bump only labels whose font
        // size is in the heading range — leaves the small top heading alone.
        let allSubviews = subviewsRecursive()
        let headingViews = allSubviews.compactMap { $0 as? DSDocumentHeadingView }
        for headingView in headingViews {
            // DSDocumentHeadingView has a private stackView; iterate its labels.
            for case let label as UILabel in headingView.subviewsRecursive() {
                guard let font = label.font else { continue }
                // Only bump labels that look like the bottom heading (size >= 17).
                // The top "Паспорт громадянина\nУкраїни" heading uses size 17-24, so
                // we want to bump it too — actually leave the top alone by checking
                // that this heading view is anchored to the bottom of its parent.
                let isBottom = headingView.frame.maxY >= self.bounds.height * 0.7
                if isBottom && font.pointSize < 30 {
                    label.font = font.withSize(font.pointSize + 4)
                }
            }
        }
        objc_setAssociatedObject(self, &Self.bottomHeadingEnlargedKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc private func forkKebabTapped() {
        forkKebabHandler?()
    }

    private var forkKebabHandler: (() -> Void)? {
        get { objc_getAssociatedObject(self, &Self.forkKebabHandlerKey) as? () -> Void }
        set { objc_setAssociatedObject(self, &Self.forkKebabHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - UIView helpers
private extension UIView {
    /// All subviews recursively (depth-first).
    func subviewsRecursive() -> [UIView] {
        var result: [UIView] = [self]
        for sub in subviews {
            result.append(contentsOf: sub.subviewsRecursive())
        }
        return result
    }
}
