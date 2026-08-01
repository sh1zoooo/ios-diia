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
///   Rather than fork the SPM package, we just overlay our own UIButton.
///
/// Implementation note:
///   `DSDocumentWithPhotoView` is a `final public class` (cannot subclass).
///   We tried swizzling `layoutSubviews`, but `DSDocumentWithPhotoView` does
///   NOT override it, so `class_getInstanceMethod` returned UIView's IMP and
///   `method_exchangeImplementations` patched UIView globally — that crashed
///   every layout pass in the app.
///   The current approach uses KVO on `bounds` — when the view gets a non-zero
///   size, we add the kebab button once. KVO is per-instance, so it cannot
///   affect other UIView subclasses.

// Top-level associated-object keys (Swift extensions can't have stored statics).
private var forkKebabKey: UInt8 = 0
private var forkKebabHandlerKey: UInt8 = 0
private var forkBottomHeadingEnlargedKey: UInt8 = 0
private var forkKebabBoundsObserverKey: UInt8 = 0
private var forkPhotoBoxHiddenKey: UInt8 = 0

extension DSDocumentWithPhotoView {

    /// Idempotent installer — currently a no-op (kept for API compatibility
    /// with AppConfigurator). The per-instance KVO hook in `forkHookOnFirstLayout`
    /// is invoked automatically the first time each DSDocumentWithPhotoView
    /// is configured.
    static func forkInstallKebabSwizzle() {
        // No global swizzle — see class doc for why.
        // Per-instance KVO is set up in forkHookOnFirstLayout(), which is called
        // from AppConfigurator after seeding each card.
    }

    /// Call this on a freshly-created DSDocumentWithPhotoView instance to
    /// install the kebab overlay once the view gets a non-zero frame.
    /// Safe to call multiple times — only the first call installs the observer.
    ///
    /// - Parameter hidePhotoBox: pass `true` for document types that never have
    ///   a photo (e.g. birth certificate). `DSTableBlockTwoColumnsPlaneOrgView`
    ///   ALWAYS adds an empty `DSDocPhotoView` placeholder whenever an
    ///   `imageProvider` is supplied — regardless of whether `models.photo` is
    ///   nil — because the check is `if let imageProvider`, not
    ///   `if let models.photo`. Since we always pass a non-nil resolver, the
    ///   only way to remove the empty box is to find and detach the view
    ///   after layout.
    func forkHookOnFirstLayout(hidePhotoBox: Bool = false) {
        if objc_getAssociatedObject(self, &forkKebabBoundsObserverKey) != nil {
            return
        }

        // If already has a non-zero size, add the kebab immediately.
        if bounds.width > 0 && bounds.height > 0 {
            forkEnsureKebabButton()
            forkEnlargeBottomHeadingFonts()
            if hidePhotoBox { forkHidePhotoBoxIfNeeded() }
            return
        }

        // Otherwise observe bounds until the view gets a real frame.
        let observer = self.observe(\.bounds, options: [.new]) { [weak self] _, _ in
            guard let self = self else { return }
            guard self.bounds.width > 0, self.bounds.height > 0 else { return }
            // Defer to next runloop to ensure other layout is done.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.forkEnsureKebabButton()
                self.forkEnlargeBottomHeadingFonts()
                if hidePhotoBox { self.forkHidePhotoBoxIfNeeded() }
            }
            // Stop observing after the first valid layout.
            if let token = objc_getAssociatedObject(self, &forkKebabBoundsObserverKey) as? NSKeyValueObservation {
                token.invalidate()
                objc_setAssociatedObject(self, &forkKebabBoundsObserverKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        objc_setAssociatedObject(self, &forkKebabBoundsObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Removes the empty photo placeholder box from the two-column block, so
    /// the field list expands to the full card width — matching the real
    /// birth-certificate card, which has no photo at all.
    private func forkHidePhotoBoxIfNeeded() {
        if objc_getAssociatedObject(self, &forkPhotoBoxHiddenKey) as? Bool == true {
            return
        }
        for case let photoView as DSDocPhotoView in subviewsRecursive() {
            photoView.removeFromSuperview()
        }
        objc_setAssociatedObject(self, &forkPhotoBoxHiddenKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func forkEnsureKebabButton() {
        if let existing = objc_getAssociatedObject(self, &forkKebabKey) as? UIButton {
            self.bringSubviewToFront(existing)
            return
        }

        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.layer.cornerRadius = 14    // half of 28 → smaller, cleaner circle
        button.clipsToBounds = true
        button.setTitle("⋯", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        // Negative content insets so the "⋯" glyph stays optically centered
        // (the glyph has weird built-in padding in most system fonts).
        button.contentEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(forkKebabTapped), for: .touchUpInside)

        addSubview(button)
        // Position: trailing 12pt, bottom 16pt.
        // The bottomHeading occupies roughly the bottom ~80pt of the card
        // (3 lines of ~21pt name + 16pt padding below). With bottom = 16pt,
        // the button's vertical center sits at ~30pt from the bottom — which
        // lines up with the patronymic line (3rd line of the multi-line name).
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
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
