//___FILEHEADER___

import UIKit
import DiiaUIComponents
import DiiaMVPModule
import DiiaCommonTypes

protocol ___VARIABLE_productName:identifier___View: BaseView {
    func setLoadingState(_ state: LoadingState)
}

final class ___FILEBASENAMEASIDENTIFIER___: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var topView: TopNavigationView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!

    @IBOutlet private weak var attentionView: ParameterizedAttentionView!
    @IBOutlet private weak var statusView: StatusInfoView!

    @IBOutlet private weak var actionButton: LoadingStateButton!
    @IBOutlet private weak var actionButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - Properties
    var presenter: ___VARIABLE_productName:identifier___Action!

    // MARK: - Init
    init() {
        super.init(nibName: ___FILEBASENAMEASIDENTIFIER___.className, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initialSetup()
        presenter.configureView()
    }

    // MARK: - Private
    private func initialSetup() {
        setupTopView()
        setupFonts()
        setupButtons()
    }

    private func setupTopView() {
        topView.setupOnClose { [weak self] in
            self?.closeModule(animated: true)
        }
    }

    private func setupFonts() {
        headerLabel.font = FontBook.detailsTitleFont
        statusView.configureFonts(title: FontBook.bigText, description: FontBook.usualFont)
    }

    private func setupButtons() {
        actionButton.setLoadingState(.enabled, withTitle: R.string.localizable.general_continue())
        actionButton.titleLabel?.font = FontBook.bigText
        actionButton.contentEdgeInsets = Constants.buttonInsets
        actionButtonBottomConstraint.constant = AppConstants.Layout.buttonBottomOffset
    }

    // MARK: - Actions
    @IBAction private func actionTapped() {
        presenter.actionTapped()
    }
}

// MARK: - View logic
extension ___FILEBASENAMEASIDENTIFIER___: ___VARIABLE_productName:identifier___View {
    func setLoadingState(_ state: LoadingState) {
        topView.setupLoading(isActive: state == .loading)
        contentView.isHidden = state == .loading
    }
}

// MARK: - Constants
extension ___FILEBASENAMEASIDENTIFIER___ {
    private enum Constants {
        static let buttonInsets = UIEdgeInsets.init(top: 0, left: 62, bottom: 0, right: 62)
    }
}
