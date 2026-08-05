// Views/Components/QRCodeScanner.swift
import SwiftUI
@preconcurrency import AVFoundation

@MainActor
protocol QRCodeScannerDelegate: AnyObject {
    func didScan(code: String)
    func didFailWithError(error: Error)
}

struct QRCodeScanner: UIViewControllerRepresentable {
    weak var delegate: QRCodeScannerDelegate?
    /// When this flips back to `true` the scanner re-arms and accepts a new code.
    /// Keep it `false` while a scanned code is being processed or while its failure
    /// is still on screen, so the same code is not submitted again immediately.
    var isScanningEnabled: Bool

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let vc = QRCodeScannerViewController()
        vc.delegate = delegate
        vc.isScanningEnabled = isScanningEnabled
        return vc
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        uiViewController.delegate = delegate
        uiViewController.isScanningEnabled = isScanningEnabled
    }
}

class QRCodeScannerViewController: UIViewController {
    weak var delegate: QRCodeScannerDelegate?

    var isScanningEnabled = true {
        didSet {
            // Re-arm as soon as the previous code has been handled and any error
            // acknowledged. Assigned on every update, so it does not rely on
            // SwiftUI delivering each intermediate state change.
            if isScanningEnabled { hasScanned = false }
        }
    }

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayView = UIView()
    private var hasScanned = false
    private var isVisible = false

    /// Every `startRunning()` / `stopRunning()` call is serialized here so a stop
    /// submitted during dismissal can never be overtaken by an earlier queued start.
    private let sessionQueue = DispatchQueue(label: "com.pingidentity.PingOneMFASample.scanner.session")

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissionAndSetup()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
        hasScanned = false
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        overlayView.frame = view.bounds
        updateMask()
    }

    private func startSession() {
        let session = captureSession
        sessionQueue.async { session?.startRunning() }
    }

    private func stopSession() {
        let session = captureSession
        sessionQueue.async { session?.stopRunning() }
    }

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor [weak self] in
                    if granted { self?.setupCamera() }
                    else { self?.delegate?.didFailWithError(error: ScannerError.permissionDenied) }
                }
            }
        default:
            delegate?.didFailWithError(error: ScannerError.permissionDenied)
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            delegate?.didFailWithError(error: ScannerError.noCameraAvailable)
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            delegate?.didFailWithError(error: ScannerError.noCameraAvailable)
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        captureSession = session
        previewLayer = preview

        // Permission may be granted after the screen was dismissed; only start if
        // still on screen, otherwise `viewWillAppear` starts it on the next present.
        if isVisible { startSession() }
    }

    private func setupOverlay() {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlayView)

        let scanBox = UIView()
        scanBox.translatesAutoresizingMaskIntoConstraints = false
        scanBox.layer.borderColor = UIColor.white.cgColor
        scanBox.layer.borderWidth = 2
        scanBox.layer.cornerRadius = 12
        overlayView.addSubview(scanBox)
        NSLayoutConstraint.activate([
            scanBox.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            scanBox.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            scanBox.widthAnchor.constraint(equalToConstant: 250),
            scanBox.heightAnchor.constraint(equalToConstant: 250)
        ])

        let label = UILabel()
        label.text = "Scan QR Code"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: scanBox.topAnchor, constant: -20)
        ])
    }

    private func updateMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        let hole = UIBezierPath(roundedRect: CGRect(
            x: overlayView.bounds.midX - 125,
            y: overlayView.bounds.midY - 125,
            width: 250, height: 250), cornerRadius: 12)
        path.append(hole)
        path.usesEvenOddFillRule = true
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        overlayView.layer.mask = mask
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        Task { @MainActor [weak self] in
            guard let self, self.isScanningEnabled, !self.hasScanned else { return }
            self.hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.delegate?.didScan(code: value)
        }
    }
}

enum ScannerError: LocalizedError {
    case noCameraAvailable
    case permissionDenied
    var errorDescription: String? {
        switch self {
        case .noCameraAvailable: return "No camera available."
        case .permissionDenied: return "Camera permission denied. Enable it in Settings."
        }
    }
}
