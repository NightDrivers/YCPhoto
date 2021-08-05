//
//  YCImageCropViewController.swift
//  HPrint
//
//  Created by ldc on 2020/5/22.
//  Copyright © 2020 Hanin. All rights reserved.
//

import Foundation
import UIKit
import BaseKitSwift
import TOCropViewController

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    
    return CGPoint.init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

extension CGPoint {
    
    var length: CGFloat { sqrt(x * x + y * y) }
}

public enum YCCropMode {
    case noCrop
    case fixableCrop(CGFloat)//TODO: 暂未完全实现
    case flexibleCrop(CGFloat)
}

public class YCImageCropViewController: UIViewController {
    
    var didCropClosure: ((UIImage, CGRect) -> Void)?
    
    var didCancelClosure: (() -> Void)?
    
    var image: UIImage
    
    let cropMode: YCCropMode
    
    let rotatable: Bool
    
    var firstTime = true
    
    init(image: UIImage, cropMode: YCCropMode, rotatable: Bool = false) {
        self.image = image
        self.rotatable = rotatable
        self.cropMode = cropMode
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        view.backgroundColor = UIColor.black
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.firstTime) {
            self.cropView.performInitialSetup()
            self.firstTime = false;
        }
    }
    
    func makeConstraint() -> Void {
        
        switch cropMode {
        case .fixableCrop(let ratio):
            cropView.aspectRatio = CGSize.init(width: ratio, height: 1)
            cropView.aspectRatioLockEnabled = true
        case .flexibleCrop(let ratio):
            cropView.aspectRatio = CGSize.init(width: ratio, height: 1)
        default:
            cropView.aspectRatio = CGSize.init(width: 1, height: 1)
        }
        cropView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(self.snp.top)
            $0.bottom.equalTo(bottomBgView.snp.top)
        }
        bottomBgView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.top.equalTo(self.snp.bottom).offset(-90)
        }
        closeButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(38)
            $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
            $0.width.height.equalTo(36)
        }
        rotateButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
            $0.width.height.equalTo(39)
        }
        okButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-38)
            $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
            $0.width.height.equalTo(36)
        }
    }
    
    public override var prefersStatusBarHidden: Bool { true }
    
    lazy var cropView: TOCropView = {
        let temp = TOCropView.init(croppingStyle: .default, image: image)
        temp.alwaysShowCroppingGrid = true
        temp.backgroundColor = UIColor.black
        view.addSubview(temp)
        return temp
    }()
    
    @objc func cropAction() {
        
        let cropFrame = self.cropView.imageCropFrame
        let angle = self.cropView.angle
        let result = image.croppedImage(withFrame: cropFrame, angle: angle, circularClip: false)
        self.didCropClosure?(result, cropFrame)
    }
    
    @objc func rotateAction() {
        
        self.cropView.rotateImageNinetyDegrees(animated: true, clockwise: false)
    }
    
    @objc func closeAction() {
        
        self.didCancelClosure?()
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var okButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setImage(getBundleImage( "image_crop_ok"), for: .normal)
        temp.addTarget(self, action: #selector(self.cropAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var closeButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setImage(getBundleImage( "image_crop_close"), for: .normal)
        temp.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var rotateButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setImage(getBundleImage( "image_crop_rotate"), for: .normal)
        temp.addTarget(self, action: #selector(self.rotateAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var bottomBgView: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.white
        view.addSubview(temp)
        return temp
    }()
}
