//
//  YCCameraViewController.swift
//  HPrint
//
//  Created by ldc on 2020/2/20.
//  Copyright © 2020 WuYB. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo
import BaseKitSwift
import Photos

extension UIView {
    
    var h_safeAreaLayoutGuide: UILayoutGuide {
        
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return readableContentGuide
        }
    }
}

class YCCameraViewController: UINavigationController {
    
    var didPickPhotoClosure: ((UIImage) -> Void)?
    
    private let hostViewController: YCCameraHostViewController
    
    init(with cropMode: YCCropMode = .noCrop, supply view: UIView? = nil) {
        self.hostViewController = YCCameraHostViewController.init(with: cropMode, supply: view)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.setNavigationBarHidden(true, animated: false)
        self.setViewControllers([self.hostViewController], animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hostViewController.didPickImageClosure = { [weak self] in
            self?.didPickPhotoClosure?($0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class YCCameraHostViewController: UIViewController {
    
    var didPickImageClosure: ((UIImage) -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let cropMode: YCCropMode
    let cameraSupplyView: UIView?
    
    init(with cropMode: YCCropMode, supply view: UIView? = nil) {
        self.cropMode = cropMode
        self.cameraSupplyView = view
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        makeConstraint()
        SJMotionOrientationManager.shared.startAccelerometerUpdates()
    }
    
    func didTakePhotoAction(_ image: UIImage, target: UIViewController, closure: @escaping (UIImage) -> Void) -> Void {
        
        switch cropMode {
        case .noCrop:
            closure(image)
        case .fixableCrop, .flexibleCrop:
            let temp = YCImageCropViewController.init(image: image, cropMode: self.cropMode, rotatable: true)
            temp.didCropClosure = { [weak temp] in
                let image = $0.sub($1)
                temp?.dismiss(animated: false, completion: {
                    closure(image)
                })
            }
            target.present(temp, animated: false, completion: nil)
        }
    }
    
    func makeConstraint() -> Void {
        
        cameraPickerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func setCameraPickerViewClosure(pickerView: YCCameraImagePickerView) -> Void {
        
        pickerView.didCapturePhotoClosure = { [weak self] in
            
            guard let self = self else { return }
            self.didTakePhotoAction($0, target: self, closure: { self.didPickImageClosure?($0) })
        }
        
        pickerView.didTouchButtonClosure = { [weak self] in
            
            guard let self = self else { return }
            switch $0 {
            case .close:
                self.dismiss(animated: true, completion: nil)
            case .photoLibrary:
                //弹出相片选择器
                PHPhotoLibrary.requestPhotoAuthorization {
                    let temp = YCImagePickerViewController.init(style: .single(needCamera: false))
                    temp.didPickPhotoClosure = { [weak temp] (images) in
                        guard let temp = temp else { return }
                        self.didTakePhotoAction(images[0], target: temp, closure: {
                            let image = $0
                            temp.dismiss(animated: false, completion: {
                                self.didPickImageClosure?(image)
                            })
                        })
                    }
                    self.present(temp, animated: true, completion: nil)
                }
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return true
    }
    
    lazy var cameraPickerView: YCCameraImagePickerView = {
        let temp = YCCameraImagePickerView.init(supply: cameraSupplyView)
        setCameraPickerViewClosure(pickerView: temp)
        view.addSubview(temp)
        return temp
    }()
    
    deinit {
        SJMotionOrientationManager.shared.stopAccelerometerUpdates()
    }
}

class YCCameraImagePickerView: UIView {
    
    enum Action {
        case close, photoLibrary
    }
    
    var didTouchButtonClosure: ((Action) -> Void)?
    
    var didCapturePhotoClosure: ((UIImage) -> Void)? {
        
        set {
            cameraView.didCapturePhotoClosure = newValue
        }
        
        get {
            return cameraView.didCapturePhotoClosure
        }
    }
    
    let supplyView: UIView?
    
    init(supply view: UIView? = nil) {
        self.supplyView = view
        super.init(frame: .zero)
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeConstraint() -> Void {
        
        let snp = h_safeAreaLayoutGuide.snp
        let horizonalPadding: CGFloat = 30
        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        if let supplyView = supplyView {
            addSubview(supplyView)
            supplyView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        torchButton.snp.makeConstraints {
            $0.top.equalTo(snp.top).offset(20)
            $0.right.equalToSuperview().offset(-horizonalPadding)
            $0.width.height.equalTo(44)
        }
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(snp.bottom).offset(-50)
            $0.left.equalToSuperview().offset(horizonalPadding)
            $0.width.height.equalTo(44)
        }
        captureButton.snp.makeConstraints {
            $0.centerY.equalTo(snp.bottom).offset(-50)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(60)
        }
        photoLibraryButton.snp.makeConstraints {
            $0.centerY.equalTo(snp.bottom).offset(-50)
            $0.right.equalToSuperview().offset(-horizonalPadding)
            $0.width.height.equalTo(44)
        }
    }
    
    @objc func buttonAction(sender: UIButton) {
        
        switch sender.tag {
        case 1:
            didTouchButtonClosure?(.close)
        case 2:
            cameraView.videoCaptureView.switchTorchMode()
        case 3:
            didTouchButtonClosure?(.photoLibrary)
        case 4:
            cameraView.capturePhoto()
        default:
            break
        }
    }
    
    lazy var cameraView: YCCameraView = {
        let temp = YCCameraView()
        addSubview(temp)
        return temp
    }()
    
    lazy var closeButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "camera_close"), for: .normal)
        temp.tag = 1
        temp.addTarget(self, action: #selector(self.buttonAction(sender:)), for: .touchUpInside)
        addSubview(temp)
        return temp
    }()
    
    lazy var torchButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "camera_torch"), for: .normal)
        temp.tag = 2
        temp.addTarget(self, action: #selector(self.buttonAction(sender:)), for: .touchUpInside)
        addSubview(temp)
        return temp
    }()
    
    lazy var photoLibraryButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "camera_photo_library"), for: .normal)
        temp.tag = 3
        temp.addTarget(self, action: #selector(self.buttonAction(sender:)), for: .touchUpInside)
        addSubview(temp)
        return temp
    }()
    
    lazy var captureButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "cameral_take_photo"), for: .normal)
        temp.tag = 4
        temp.addTarget(self, action: #selector(self.buttonAction(sender:)), for: .touchUpInside)
        addSubview(temp)
        return temp
    }()
}

class YCCameraView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeConstraint()
    }
    
    var didCapturePhotoClosure: ((UIImage) -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeConstraint() -> Void {
        
        videoCaptureView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func capturePhoto() -> Void {
        
        if #available(iOS 10, *) {
            let settings = AVCapturePhotoSettings.init(format: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
            settings.isHighResolutionPhotoEnabled = true
            photoOutput.capturePhoto(with: settings, delegate: self)
        }else {
            if let connection = stillImageOutput.connection(with: .video) {
                stillImageOutput.captureStillImageAsynchronously(from: connection, completionHandler: { (buffer, error) in
                    if let error = error {
                        print(error)
                    }
                    guard let photoSampleBuffer = buffer else { return }
                    let image = UIImage.image(sample: photoSampleBuffer, device: UIDevice.current.orientation)
                    self.didCapturePhotoClosure?(image)
                })
            }
        }
    }
    
    lazy var videoCaptureView: YCVideoCaptureSessionView = {
        let temp = YCVideoCaptureSessionView()
        if #available(iOS 10.0, *) {
            temp.output = photoOutput
        } else {
            temp.output = stillImageOutput
        }
        addSubview(temp)
        return temp
    }()
    
    @available(iOS 10.0, *)
    lazy var photoOutput: AVCapturePhotoOutput = {
        let temp = AVCapturePhotoOutput()
        temp.isHighResolutionCaptureEnabled = true
        return temp
    }()
    
    lazy var stillImageOutput: AVCaptureStillImageOutput = {
        let temp = AVCaptureStillImageOutput()
        temp.isHighResolutionStillImageOutputEnabled = true
        temp.outputSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        return temp
    }()
}

extension YCCameraView: AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let buffer = photo.pixelBuffer else { return }
        let image = UIImage.image(pixel: buffer, device: UIDevice.current.orientation)
        didCapturePhotoClosure?(image)
    }
    
    @available(iOS, introduced: 10.0, deprecated: 11.0)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let photoSampleBuffer = photoSampleBuffer else { return }
        let image = UIImage.image(sample: photoSampleBuffer, device: UIDevice.current.orientation)
        didCapturePhotoClosure?(image)
    }
}

class YCVideoCaptureSessionView: UIView {
    
    private let session: AVCaptureSession
    let previewLayer: AVCaptureVideoPreviewLayer
    var output: AVCaptureOutput? {
        
        didSet {
            guard let output = output else { return }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        }
    }
    private var captureDevice: AVCaptureDevice?
    
    override init(frame: CGRect) {
        
        session = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init(frame: frame)
        self.layer.addSublayer(previewLayer)
        
        do {
            if let device = AVCaptureDevice.default(for: .video) {
                self.captureDevice = device
                let input = try AVCaptureDeviceInput.init(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            }
        }catch let error {
            print(error)
        }
        //FIXME: 这个会卡主线程
        self.session.startRunning()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
    
    func switchTorchMode() -> Void {
        
        if let device = captureDevice {
            switch device.torchMode {
            case .on:
                if device.isTorchModeSupported(.off) {
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    } catch {
                        print(error)
                    }
                }
            case .off, .auto:
                if device.isTorchModeSupported(.on) {
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = .on
                        device.unlockForConfiguration()
                    } catch {
                        print(error)
                    }
                }
            @unknown default:
                break
            }
        }
    }
}
