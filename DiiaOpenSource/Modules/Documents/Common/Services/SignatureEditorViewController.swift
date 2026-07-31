import UIKit

/// FORK: a small finger-drawing canvas the user opens from the Passport edit form.
/// Lets the user draw their signature on a black-on-white background, then
/// "Save" persists it as PNG into `PassportStorage` and "Clear" wipes the canvas.
///
/// Includes a brush-thickness slider (1pt ... 8pt) above the canvas.
final class SignatureEditorViewController: UIViewController {

    private let canvasView = SignatureCanvasView()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "Намалюйте підпис пальцем нижче"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .darkGray
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let brushThicknessLabel: UILabel = {
        let l = UILabel()
        l.text = "Товщина кисті: 3"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()

    private let brushSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 8
        s.value = 3
        s.isContinuous = true
        return s
    }()

    private let clearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Очистити", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.lightGray.cgColor
        return b
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Зберегти", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.backgroundColor = .black
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        return b
    }()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Скасувати", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Підпис"
        view.backgroundColor = .systemBackground

        setupLayout()

        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        brushSlider.addTarget(self, action: #selector(brushThicknessChanged(_:)), for: .valueChanged)

        // Apply initial brush thickness from slider default.
        canvasView.brushWidth = CGFloat(brushSlider.value)

        // If there's already a signature, preload it onto the canvas.
        if let existing = PassportStorage.shared.signatureImage {
            canvasView.loadExistingImage(existing)
        }
    }

    private func setupLayout() {
        [hintLabel, brushThicknessLabel, brushSlider, canvasView,
         clearButton, saveButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            hintLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            brushThicknessLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
            brushThicknessLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            brushThicknessLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            brushSlider.topAnchor.constraint(equalTo: brushThicknessLabel.bottomAnchor, constant: 8),
            brushSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            brushSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            canvasView.topAnchor.constraint(equalTo: brushSlider.bottomAnchor, constant: 16),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor, multiplier: 0.5),

            clearButton.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 24),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.heightAnchor.constraint(equalToConstant: 44),

            saveButton.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    @objc private func brushThicknessChanged(_ slider: UISlider) {
        let value = Int(slider.value.rounded())
        brushThicknessLabel.text = "Товщина кисті: \(value)"
        canvasView.brushWidth = CGFloat(slider.value)
        canvasView.setNeedsDisplay()
    }

    @objc private func clearTapped() {
        canvasView.clear()
    }

    @objc private func saveTapped() {
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

    @objc private func cancelTapped() {
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
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
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
    ///
    /// Why white instead of transparent?
    ///   DSTableItemVerticalView.configure() calls
    ///   `image.imageByMakingWhiteBackgroundTransparent()` on the signature
    ///   image before scaling it. That function uses
    ///   `copy(maskingColorComponents: [200,255,200,255,200,255])` which
    ///   knocks out white-ish pixels but LEAVES already-transparent pixels
    ///   alone. If we render with a transparent background, the masking pass
    ///   is essentially a no-op AND the resulting image keeps its alpha
    ///   channel — which for some reason makes the UIImageView in
    ///   DSTableItemVerticalView render nothing visible.
    ///   Rendering with a white background and letting Diia's masking pass
    ///   make that white transparent matches the original Diia flow
    ///   (their backend returns signature JPEGs with white backgrounds).
    func renderedImage() -> UIImage? {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // White background — Diia's imageByMakingWhiteBackgroundTransparent()
            // will strip this in DSTableItemVerticalView.
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
