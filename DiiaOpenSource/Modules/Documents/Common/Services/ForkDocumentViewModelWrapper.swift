import Foundation
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaNetwork
import DiiaCommonTypes
import DiiaUIComponents
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore
import DiiaDocuments

/// FORK: wraps a `DriverLicenseViewModel` and overrides ONLY `backView(for:flippingAction:)`
/// to return a local, offline QR code view instead of the network-driven
/// `QRCodeBarcodeView` (which calls `sharingRequest()` and needs the Diia backend).
///
/// Every other DocumentModel method is forwarded to the wrapped viewModel.
/// This is necessary because `DriverLicenseViewModel` is `public final` —
/// we can't subclass it to override `backView`.
final class ForkDocumentViewModelWrapper: DocumentModel {

    private let wrapped: DriverLicenseViewModel
    /// FORK: stored fork-doc-type (passport / birthCertificate / driverLicense).
    /// Distinct name from the protocol's `docType: DocumentAttributesProtocol?`
    /// to avoid an invalid redeclaration error.
    private let forkDocType: DocType

    init(wrapped: DriverLicenseViewModel, docType: DocType) {
        self.wrapped = wrapped
        self.forkDocType = docType
    }

    // MARK: - Forwarded properties
    var id: String { wrapped.id }
    var model: DSDocumentData? { wrapped.model }
    var orderIdentifier: String { wrapped.orderIdentifier }
    var docType: DocumentAttributesProtocol? { wrapped.docType }
    var shortDescription: String { wrapped.shortDescription }
    var orderConfigurations: DataOrderConfigurations? { wrapped.orderConfigurations }
    var isDocumentValid: Bool { wrapped.isDocumentValid }
    var frontView: FrontViewProtocol { wrapped.frontView }
    var accessibilityDescription: String? { wrapped.accessibilityDescription }
    var documentName: String? { wrapped.documentName }

    // MARK: - Forwarded methods
    func backView(for type: VerificationType?, flippingAction: @escaping Callback) -> FlippableEmbeddedView? {
        // FORK: return our own offline QR view instead of the network-driven one.
        return ForkQRBackView(docType: forkDocType, flippingAction: flippingAction)
    }

    func sharingRequest() -> Signal<ShareLinkModel, NetworkError>? {
        return wrapped.sharingRequest()
    }

    func getCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]] {
        return wrapped.getCardActions(view: view, flipper: flipper)
    }

    func getInstackCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]] {
        return wrapped.getInstackCardActions(view: view, flipper: flipper)
    }

    func getAccessibilityMenuAction(view: BaseView, flipper: FlipperVerifyProtocol, inStack: Bool) -> [[Action]] {
        return wrapped.getAccessibilityMenuAction(view: view, flipper: flipper, inStack: inStack)
    }

    func updateIfNeeded() {
        wrapped.updateIfNeeded()
    }
}

/// FORK: offline QR back view for the document card.
/// Renders a static QR code (no network call) encoding a fixed YouTube URL,
/// plus the doc name as a title. Tapping the QR opens the URL in the system
/// browser. Conforms to FlippableEmbeddedView so the cell's flip animation
/// can drive willPresent/willHide/didHide.
final class ForkQRBackView: UIView, FlippableEmbeddedView {

    private let docType: DocType
    private let flippingAction: Callback

    /// The URL encoded in the QR code and opened on tap.
    /// FORK: hard-coded YouTube link as requested by the user.
    private let qrURLString = "https://m.youtube.com/watch?v=AsrAF5CvnP4&list=RDAsrAF5CvnP4&start_radio=1&pp=ygUu0J_QtdC70YzQvNC40L3QuCDQvNCw0YHQu9C-INC00LDQvNCx0LvQuNC90LPQuKAHAQ%3D%3D&ra=m"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = FontBook.cardsHeadingFont
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = FontBook.bigText
        l.textColor = .darkGray
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    init(docType: DocType, flippingAction: @escaping Callback) {
        self.docType = docType
        self.flippingAction = flippingAction
        super.init(frame: .zero)
        setupLayout()
        fillContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, qrImageView, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        // Layout: title at top, QR centered horizontally AND vertically in the
        // remaining space, subtitle below QR. Symmetric padding around the QR
        // so it visually sits in the middle of the card.
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // QR centered horizontally
            qrImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            // QR centered vertically between the title and the subtitle
            qrImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 8),
            // QR size: 60% of card width, square
            qrImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            qrImageView.heightAnchor.constraint(equalTo: qrImageView.widthAnchor),

            // Subtitle pinned to bottom, centered horizontally
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])

        // Tap on the QR opens the URL
        let tap = UITapGestureRecognizer(target: self, action: #selector(qrTapped))
        qrImageView.addGestureRecognizer(tap)
    }

    private func fillContent() {
        titleLabel.text = docType.name

        // QR encodes the hard-coded YouTube URL.
        qrImageView.image = .qrCode(from: qrURLString)

        // Subtitle: doc number + full name (whichever is non-empty).
        let docNumber: String
        let subtitle: String
        switch docType {
        case .passport:
            let s = PassportStorage.shared.snapshot()
            docNumber = s.number
            subtitle = PassportStorage.shared.fullName
        case .birthCertificate:
            let s = BirthCertificateStorage.shared.snapshot()
            docNumber = s.recordNumber
            subtitle = BirthCertificateStorage.shared.fullName
        case .driverLicense:
            let s = DriverLicenseStorage.shared.snapshot()
            docNumber = s.number
            subtitle = s.fullName
        case .taxpayerСard:
            docNumber = ""
            subtitle = ""
        }

        var subtitleText = ""
        if !subtitle.isEmpty { subtitleText += subtitle }
        if !docNumber.isEmpty {
            if !subtitleText.isEmpty { subtitleText += "\n" }
            subtitleText += docNumber
        }
        subtitleLabel.text = subtitleText
    }

    @objc private func qrTapped() {
        guard let url = URL(string: qrURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - FlippableEmbeddedView
    func willPresent() {}
    func willHide() {}
    func didHide() {}
    func didChangeFocus(isFocused: Bool) {}
    func changeVerificationView(for verificationType: VerificationType) {}
}

