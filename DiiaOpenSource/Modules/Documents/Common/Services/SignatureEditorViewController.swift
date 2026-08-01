import UIKit
import Lottie

/// FORK: signature editor in Diia style — animated gradient background,
/// white rounded cards containing the canvas + brush slider, primary Save
/// button at the bottom.
final class SignatureEditorViewController: UIViewController {

    private let canvasView = SignatureCanvasView()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "Намалюйте підпис пальцем у полі нижче"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 0.40, alpha: 1.0)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let brushCardTitle: UILabel = {
        let l = UILabel()
        l.text = "ТОВЩИНА КИСТІ"
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = UIColor(white: 0.40, alpha: 1.0)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let brushValueLabel: UILabel = {
        let l = UILabel()
        l.text = "3"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let brushSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 8
        s.value = 3
        s.isContinuous = true
        s.translatesAutoresizingMaskIntoConstraints = false
        s.minimumTrackTintColor = .black
        return s
    }()

    private let clearButton: ForkFormButtonView = {
        let b = ForkFormButtonView(title: "Очистити", style: .secondary, onTap: {})
        return b
    }()

    private let saveButton: ForkFormButtonView = {
        let b = ForkFormButtonView(title: "Зберегти", style: .primary, onTap: {})
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Підпис"
        view.backgroundColor = .white

        setupBackground()
        setupLayout()

        clearButton.onTap = { [weak self] in self?.clearTapped() }
        saveButton.onTap = { [weak self] in self?.saveTapped() }
        brushSlider.addTarget(self, action: #selector(brushThicknessChanged(_:)), for: .valueChanged)

        // Apply initial brush thickness from slider default.
        canvasView.brushWidth = CGFloat(brushSlider.value)

        // If there's already a signature, preload it onto the canvas.
        if let existing = PassportStorage.shared.signatureImage {
            canvasView.loadExistingImage(existing)
        }
    }

    // MARK: - Background

    private func setupBackground() {
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
    }

    // MARK: - Layout

    private func setupLayout() {
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

        // Buttons pinned to bottom.
        let buttonsStack = UIStackView()
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 8
        buttonsStack.alignment = .fill
        buttonsStack.distribution = .fill
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
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

        // Hint label
        contentStack.addArrangedSubview(hintLabel)

        // Card 1: Canvas
        let canvasCard = makeCard()
        canvasCard.addSubview(canvasView)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: canvasCard.topAnchor, constant: 16),
            canvasView.bottomAnchor.constraint(equalTo: canvasCard.bottomAnchor, constant: -16),
            canvasView.leadingAnchor.constraint(equalTo: canvasCard.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: canvasCard.trailingAnchor, constant: -16),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor, multiplier: 0.5),
        ])
        contentStack.addArrangedSubview(canvasCard)

        // Card 2: Brush thickness slider
        let brushCard = makeCard()
        brushCard.addSubview(brushCardTitle)
        brushCard.addSubview(brushValueLabel)
        brushCard.addSubview(brushSlider)
        NSLayoutConstraint.activate([
            brushCardTitle.topAnchor.constraint(equalTo: brushCard.topAnchor, constant: 16),
            brushCardTitle.leadingAnchor.constraint(equalTo: brushCard.leadingAnchor, constant: 16),

            brushValueLabel.centerYAnchor.constraint(equalTo: brushCardTitle.centerYAnchor),
            brushValueLabel.trailingAnchor.constraint(equalTo: brushCard.trailingAnchor, constant: -16),

            brushSlider.topAnchor.constraint(equalTo: brushCardTitle.bottomAnchor, constant: 12),
            brushSlider.leadingAnchor.constraint(equalTo: brushCard.leadingAnchor, constant: 16),
            brushSlider.trailingAnchor.constraint(equalTo: brushCard.trailingAnchor, constant: -16),
            brushSlider.bottomAnchor.constraint(equalTo: brushCard.bottomAnchor, constant: -16),
        ])
        contentStack.addArrangedSubview(brushCard)

        // Bottom buttons
        buttonsStack.addArrangedSubview(saveButton)
        buttonsStack.addArrangedSubview(clearButton)
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        return card
    }

    // MARK: - Actions

    @objc private func brushThicknessChanged(_ slider: UISlider) {
        let value = Int(slider.value.rounded())
        brushValueLabel.text = "\(value)"
        canvasView.brushWidth = CGFloat(slider.value)
        canvasView.setNeedsDisplay()
    }

    private func clearTapped() {
        canvasView.clear()
    }

    private func saveTapped() {
        guard let image = canvasView.renderedImage() else {
            let alert = UIAlertController(title: "Підпис порожній",
                                          message: "Намалюйте підпис перед збереженням.",
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        PassportStorage.shared.saveSignature(image)
        PassportSeeder.sync()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - SignatureCanvasView

private final class SignatureCanvasView: UIView {

    private var strokes: [[CGPoint]] = []
    private var currentStroke: [CGPoint] = []

    /// Set when an existing signature is loaded from storage — rendered as the
    /// starting image so the user can keep editing on top of it.
    private var backgroundImage: UIImage?

    /// Brush thickness in points (1...8). Updated live from the slider.
    var brushWidth: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.96, alpha: 1.0)  // very light gray so it's distinct from the white card
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.masksToBounds = true
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadExistingImage(_ image: UIImage) {
        backgroundImage = image
        setNeedsDisplay()
    }

    func clear() {
        strokes.removeAll()
        currentStroke.removeAll()
        backgroundImage = nil
        setNeedsDisplay()
    }

    /// Renders the canvas to a UIImage — WHITE background, black strokes.
    /// (Diia's DSTableItemVerticalView calls imageByMakingWhiteBackgroundTransparent()
    /// which knocks out white pixels; keeping the white bg here is what makes
    /// the signature actually render on the document card.)
    func renderedImage() -> UIImage? {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            if let bg = backgroundImage {
                bg.draw(in: CGRect(origin: .zero, size: size))
            }

            UIColor.black.setStroke()
            let line = UIBezierPath()
            line.lineWidth = brushWidth
            line.lineCapStyle = .round
            line.lineJoinStyle = .round

            for stroke in strokes + [currentStroke] {
                guard let first = stroke.first else { continue }
                line.move(to: first)
                for pt in stroke.dropFirst() {
                    line.addLine(to: pt)
                }
            }
            line.stroke()
        }
    }

    override func draw(_ rect: CGRect) {
        backgroundColor?.setFill()
        UIRectFill(rect)

        backgroundImage?.draw(in: rect)

        UIColor.black.setStroke()
        let path = UIBezierPath()
        path.lineWidth = brushWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        for stroke in strokes + [currentStroke] {
            guard let first = stroke.first else { continue }
            path.move(to: first)
            for pt in stroke.dropFirst() {
                path.addLine(to: pt)
            }
        }
        path.stroke()
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let pt = touches.first?.location(in: self) else { return }
        currentStroke = [pt]
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let pt = touches.first?.location(in: self) else { return }
        currentStroke.append(pt)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !currentStroke.isEmpty {
            strokes.append(currentStroke)
            currentStroke.removeAll()
        }
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentStroke.removeAll()
        setNeedsDisplay()
    }
}
