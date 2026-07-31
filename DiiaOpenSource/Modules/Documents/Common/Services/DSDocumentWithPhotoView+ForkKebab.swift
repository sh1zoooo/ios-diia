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

// Top-level associated-object keys (Swift extensions can't have stored statics).
private var forkKebabKey: UInt8 = 0
private var forkKebabHandlerKey: UInt8 = 0
private var forkBottomHeadingEnlargedKey: UInt8 = 0

extension DSDocumentWithPhotoView {

    /// Idempotent installer — call once at app launch (e.g. from
    /// `AppConfigurator.configureApp()`).
    static func forkInstallKebabSwizzle() {
        let originalSelector = #selector(layoutSubviews)
        let swizzledSelector = #selector(forkLayoutSubviews)
        guard
            let originalMethod = class_getInstanceMethod(DSDocumentWithPhotoView.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(DSDocumentWithPhotoView.self, swizzledSelector)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private func forkLayoutSubviews() {
        // After exchange, this calls the original layoutSubviews.
        self.forkLayoutSubviews()
        forkEnsureKebabButton()
        forkEnlargeBottomHeadingFonts()
    }

    private func forkEnsureKebabButton() {
        if let existing = objc_getAssociatedObject(self, &forkKebabKey) as? UIButton {
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

        objc_setAssociatedObject(self, &forkKebabKey, button, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        forkKebabHandler = { [weak self] in
            self?.contextMenuCallback?()
        }
    }

    private func forkEnlargeBottomHeadingFonts() {
        if objc_getAssociatedObject(self, &forkBottomHeadingEnlargedKey) as? Bool == true {
            return
        }
        let allSubviews = subviewsRecursive()
        let headingViews = allSubviews.compactMap { $0 as? DSDocumentHeadingView }
        for headingView in headingViews {
            for case let label as UILabel in headingView.subviewsRecursive() {
                guard let font = label.font else { continue }
                let isBottom = headingView.frame.maxY >= self.bounds.height * 0.7
                if isBottom && font.pointSize < 30 {
                    label.font = font.withSize(font.pointSize + 4)
                }
            }
        }
        objc_setAssociatedObject(self, &forkBottomHeadingEnlargedKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc private func forkKebabTapped() {
        forkKebabHandler?()
    }

    private var forkKebabHandler: (() -> Void)? {
        get { objc_getAssociatedObject(self, &forkKebabHandlerKey) as? () -> Void }
        set { objc_setAssociatedObject(self, &forkKebabHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - UIView helpers
private extension UIView {
    func subviewsRecursive() -> [UIView] {
        var result: [UIView] = [self]
        for sub in subviews {
            result.append(contentsOf: sub.subviewsRecursive())
        }
        return result
    }
}
