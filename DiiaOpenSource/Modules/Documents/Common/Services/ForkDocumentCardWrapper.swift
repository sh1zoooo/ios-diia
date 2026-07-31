import UIKit
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore
import DiiaMVPModule
import DiiaUIComponents

/// FORK: wraps the standard `DSDocumentWithPhotoView` and overlays a black
/// circular "⋯" (kebab) button in the bottom-right corner, on top of the
/// bottomHeading (full-name area) — matching the original Diia card.
///
/// Why a wrapper instead of using `DSDocumentHeading.iconAtm`?
///   `DSDocumentHeadingView` looks up the icon via `UIComponentsConfiguration
///   .shared.imageProvider.imageForCode(...)` which uses `Bundle.module`
///   (the DiiaUIComponents SPM bundle). Our local asset catalog is not visible
///   there, so the kebab image would not render. Rather than fork the SPM
///   package, we just overlay our own button.
final class ForkDocumentCardWrapper<Inner: UIView & FrontViewProtocol>: UIView, FrontViewProtocol {

    let inner: Inner
    var contextMenuCallback: Callback? {
        get { inner.contextMenuCallback }
        set { inner.contextMenuCallback = newValue }
    }

    private let kebabButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .black
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        b.tintColor = .white
        b.setTitle("⋯", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        b.setTitleColor(.white, for: .normal)
        b.contentVerticalAlignment = .center
        b.contentHorizontalAlignment = .center
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    init(inner: Inner) {
        self.inner = inner
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        inner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inner)
        inner.fillSuperview()

        addSubview(kebabButton)
        NSLayoutConstraint.activate([
            kebabButton.widthAnchor.constraint(equalToConstant: 36),
            kebabButton.heightAnchor.constraint(equalToConstant: 36),
            // Place above the bottom-heading area, ~20pt from the trailing edge
            // and ~64pt from the bottom (so it sits next to the patronymic line).
            kebabButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            kebabButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -56)
        ])

        kebabButton.addTarget(self, action: #selector(kebabTapped), for: .touchUpInside)
    }

    @objc private func kebabTapped() {
        // For now, the kebab just shows the standard action sheet.
        // The real Diia opens a context menu (rate / reorder / faq).
        (window?.rootViewController?.visibleViewController)?.flatMap { _ in
            // no-op: actual actions wired through contextMenuCallback on the
            // underlying DSDocumentWithPhotoView; tapping the kebab here
            // mirrors that by forwarding the call.
        }
        contextMenuCallback?()
    }

    // MARK: - FrontViewProtocol forwarding
    func willPresent() { inner.willPresent() }
    func willHide() { inner.willHide() }
    func didHide() { inner.didHide() }
    func didChangeFocus(isFocused: Bool) { inner.didChangeFocus(isFocused: isFocused) }
    func changeVerificationView(for verificationType: VerificationType) {
        inner.changeVerificationView(for: verificationType)
    }
    func setLoadingState(_ state: DSDocumentState) { inner.setLoadingState(state) }
    func setErrorDescriptionTrailing(offset: CGFloat) {
        inner.setErrorDescriptionTrailing(offset: offset)
    }
    func verifyDocumentViewDidChangeLayout() { inner.verifyDocumentViewDidChangeLayout() }
}
