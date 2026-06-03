// Views/Components/QRCodeScanner.swift
import SwiftUI
@preconcurrency import AVFoundation

protocol QRCodeScannerDelegate: AnyObject {
    func didScan(code: String)
    func didFailWithError(error: Error)
}

struct QRCodeScanner: UIViewControllerRepresentable {
    weak var delegate: QRCodeScannerDelegate?

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let vc = QRCodeScannerViewController()
        vc.delegate = delegate
        return vc
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        uiViewController.delegate = delegate
    }
}

class QRCodeScannerViewController: UIViewController {
    weak var delegate: QRCodeScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayView = UIView()
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissionAndSetup()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        overlayView.frame = view.bounds
        updateMask()
    }

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
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
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
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
            guard let self, !self.hasScanned else { return }
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
