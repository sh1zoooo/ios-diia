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
    private let docType: DocType

    init(wrapped: DriverLicenseViewModel, docType: DocType) {
        self.wrapped = wrapped
        self.docType = docType
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
        return ForkQRBackView(docType: docType, flippingAction: flippingAction)
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
/// Renders a static QR code (no network call) encoding the docNumber, plus
/// the doc name as a title. Conforms to FlippableEmbeddedView so the cell's
/// flip animation can drive willPresent/willHide/didHide.
final class ForkQRBackView: UIView, FlippableEmbeddedView {

    private let docType: DocType
    private let flippingAction: Callback

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

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            qrImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            qrImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            qrImageView.heightAnchor.constraint(equalTo: qrImageView.widthAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    private func fillContent() {
        titleLabel.text = docType.name

        // Build a deterministic QR payload from the user-entered doc number
        // (and name for the passport). No network call.
        let storage: DocumentVisibilityStorage.DocKind? = {
            switch docType {
            case .passport:          return .passport
            case .birthCertificate:  return .birthCertificate
            case .driverLicense:     return .driverLicense
            case .taxpayerСard:      return nil
            }
        }()

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

        let payload = "DIIA-FORK|\(docType.rawValue)|\(docNumber)|\(subtitle)"
        qrImageView.image = .qrCode(from: payload)
        subtitleLabel.text = subtitle.isEmpty ? docNumber : "\(subtitle)\n\(docNumber)"
    }

    // MARK: - FlippableEmbeddedView
    func willPresent() {}
    func willHide() {}
    func didHide() {}
    func didChangeFocus(isFocused: Bool) {}
    func changeVerificationView(for verificationType: VerificationType) {}
}
