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

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    
    return CGPoint.init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

extension CGPoint {
    
    var length: CGFloat { sqrt(x * x + y * y) }
}

enum YCCropMode {
    case noCrop
    case fixableCrop(CGFloat)//TODO: 暂未完全实现
    case flexibleCrop(CGFloat)
}

extension UIImage {
    
    func sub(_ ratioRect: CGRect) -> UIImage {
        
        let rect = CGRect.init(x: self.pixelWidth*ratioRect.origin.x, 
                               y: self.pixelHeight*ratioRect.origin.y, 
                               width: self.pixelWidth*ratioRect.width, 
                               height: self.pixelHeight*ratioRect.height)
        return self.crop(pixelRect: rect)
    }
}

class YCImageCropViewController: UIViewController {
    
    var didCropClosure: ((UIImage, CGRect) -> Void)?
    
    var image: UIImage
    
    let cropMode: YCCropMode
    
    let rotatable: Bool
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeConstraint()
        view.backgroundColor = UIColor.black
    }
    
    func makeConstraint() -> Void {
        
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
            $0.left.equalToSuperview().offset(25)
            $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
            $0.width.height.equalTo(44)
        }
        okButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
            $0.width.height.equalTo(60)
        }
        if rotatable {
            rotateButton.snp.makeConstraints {
                $0.right.equalToSuperview().offset(-25)
                $0.centerY.equalTo(bottomBgView.snp.top).offset(45)
                $0.width.height.equalTo(44)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    lazy var cropView: YCCropView = {
        let temp = YCCropView.init(image: image, cropMode: cropMode)
        temp.backgroundColor = UIColor.black
        view.addSubview(temp)
        return temp
    }()
    
    @objc func cropAction() {
        
        self.didCropClosure?(self.image, self.cropView.cropRegion)
    }
    
    @objc func rotateAction() {
        
        self.image = self.image.rotate90(clockwise: true)
        var rect = self.cropView.cropRegion
        rect = CGRect.init(x: 1 - rect.origin.y - rect.height, 
                    y: rect.origin.x, 
                    width: rect.height, 
                    height: rect.width)
        self.cropView.image = self.image
        self.cropView.cropRegion = rect
    }
    
    @objc func closeAction() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var okButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "image_crop_ok"), for: .normal)
        temp.addTarget(self, action: #selector(self.cropAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var closeButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "camera_close"), for: .normal)
        temp.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var rotateButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.monitorDeviceOrientation()
        temp.setImage(#imageLiteral(resourceName: "icon_rotate"), for: .normal)
        temp.addTarget(self, action: #selector(self.rotateAction), for: .touchUpInside)
        bottomBgView.addSubview(temp)
        return temp
    }()
    
    lazy var bottomBgView: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.init(number: 0x3E3E3EFF)
        view.addSubview(temp)
        return temp
    }()
}

class YCCropView: UIView {
    
    fileprivate var _cropRegion: CGRect = .zero
    
    var cropRegion: CGRect {
        
        get {
            let locationRect = cropPlaceholderView.frame
            let baseRect = imageView.frame
            let x = (locationRect.origin.x - baseRect.origin.x)/baseRect.width
            let y = (locationRect.origin.y - baseRect.origin.y)/baseRect.height
            let widthRate = locationRect.width/baseRect.width
            let heightRate = locationRect.height/baseRect.height
            _cropRegion = CGRect.init(x: x, y: y, width: widthRate, height: heightRate)
            return _cropRegion
        }
        
        set {
            _cropRegion = newValue
            didLayout = false
            let baseRect = imageView.frame
            cropPlaceholderView.frame = CGRect.init(
                x: baseRect.origin.x + newValue.origin.x * baseRect.width, 
                y: baseRect.origin.y + newValue.origin.y * baseRect.height, 
                width: baseRect.width * newValue.width, 
                height: baseRect.height * newValue.height
            )
        }
    }
    
    var image: UIImage {
        
        didSet {
            imageView.image = image
            didLayout = false
            remakeConstraint()
        }
    }
    var didLayout = false
    
    let cropMode: YCCropMode
    
    init(image: UIImage, cropMode: YCCropMode = .flexibleCrop(1)) {
        self.image = image
        self.cropMode = cropMode
        let size = image.size
        
        let ratio: CGFloat
        switch cropMode {
        case .noCrop:
            ratio = 1
        case .fixableCrop(let _ratio):
            ratio = _ratio
        case .flexibleCrop(let _ratio):
            ratio = _ratio
        }
        let scale = min(size.width/ratio, size.height)
        let w = scale*ratio
        let h = scale
        _cropRegion = CGRect.init(
            x: (size.width - w)/2/size.width, 
            y: (size.height - h)/2/size.height, 
            width: w/size.width, 
            height: h/size.height
        )
        super.init(frame: .zero)
        backgroundColor = UIColor.darkGray
        remakeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !didLayout {
            cropPlaceholderView.maxRegion = imageView.frame
            cropRegion = _cropRegion
            didLayout = true
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        return cropPlaceholderView
    }
    
    func remakeConstraint() -> Void {
        
        let padding: CGFloat = 20
        imageView.snp.remakeConstraints {
            $0.top.left.greaterThanOrEqualToSuperview().offset(padding)
            $0.bottom.right.lessThanOrEqualToSuperview().offset(-padding)
            
            $0.top.left.equalToSuperview().offset(padding).priorityMedium()
            $0.bottom.right.equalToSuperview().offset(-padding).priorityMedium()
            
            $0.center.equalToSuperview()
            $0.width.equalTo(imageView.snp.height).multipliedBy(image.size.ratio)
        }
    }
    
    lazy var imageView: UIImageView = {
        let temp = UIImageView()
        temp.image = image
        addSubview(temp)
        return temp
    }()
    
    fileprivate lazy var cropPlaceholderView: CropRegionView = {
        let temp = CropRegionView()
        switch cropMode {
        case .flexibleCrop:
            temp.editStyle = .flexible([.leftTop, .leftBottom, .rightTop, .rightBottom, .top, .bottom, .left, .right, .translate])
        case .fixableCrop:
            temp.editStyle = .fixableRatio([.leftTop, .leftBottom, .rightTop, .rightBottom, .translate])
        case .noCrop:
            temp.editStyle = .fixableRatio([])
        }
        temp.backgroundColor = UIColor.clear
        addSubview(temp)
        return temp
    }()
}

class YCFrameEditableView: UIView {
    
    struct EventOptionSet: OptionSet {
        
        var rawValue: UInt16
        
        typealias RawValue = UInt16
        
        static let leftTop = EventOptionSet.init(rawValue: 1)
        static let leftBottom = EventOptionSet.init(rawValue: 1 << 1)
        static let rightTop = EventOptionSet.init(rawValue: 1 << 2)
        static let rightBottom = EventOptionSet.init(rawValue: 1 << 3)
        static let top = EventOptionSet.init(rawValue: 1 << 4)
        static let bottom = EventOptionSet.init(rawValue: 1 << 5)
        static let left = EventOptionSet.init(rawValue: 1 << 6)
        static let right = EventOptionSet.init(rawValue: 1 << 7)
        static let translate = EventOptionSet.init(rawValue: 1 << 8)
    }
    
    enum EditStyle {
        case flexible(EventOptionSet)
        case fixableRatio(EventOptionSet)
        
        var events: EventOptionSet {
            switch self {
            case .flexible(let events):
                return events
            case .fixableRatio(let events):
                return events
            }
        }
    }
    
    private enum TriggerPoint {
        case none, leftTop, leftBottom, rightTop, rightBottom, left, right, top, bottom, translate
    }
    
    var editStyle: EditStyle = .fixableRatio([.leftTop, .leftBottom, .rightTop, .rightBottom, .top, .bottom, .left, .right, .translate])
    
    private var trigglePoint = TriggerPoint.none
    var touchMinSize: CGFloat = 44
    var maxRegion: CGRect = UIScreen.main.bounds
    var minSize: CGSize = CGSize.init(width: 88, height: 88)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let events = editStyle.events
        if events.isEmpty {
            return
        }
        guard let location = touches.first?.location(in: self) else { return }
        let rect = CGRect.init(x: -touchMinSize/2, y: -touchMinSize/2, width: touchMinSize, height: touchMinSize)
        let top = CGRect.init(x: touchMinSize/2, y: -touchMinSize/2, width: width - touchMinSize, height: touchMinSize)
        let left = CGRect.init(x: -touchMinSize/2, y: touchMinSize/2, width: touchMinSize, height: height - touchMinSize)
        if rect.contains(location) {
            guard events.contains(.leftTop) else { return }
            trigglePoint = .leftTop
        }else if rect.offsetBy(dx: 0, dy: height).contains(location) {
            guard events.contains(.leftBottom) else { return }
            trigglePoint = .leftBottom
        }else if rect.offsetBy(dx: width, dy: 0).contains(location) {
            guard events.contains(.rightTop) else { return }
            trigglePoint = .rightTop
        }else if rect.offsetBy(dx: width, dy: height).contains(location) {
            guard events.contains(.rightBottom) else { return }
            trigglePoint = .rightBottom
        }else if left.contains(location) {
            guard events.contains(.left) else { return }
            trigglePoint = .left
        }else if left.offsetBy(dx: width, dy: 0).contains(location) {
            guard events.contains(.right) else { return }
            trigglePoint = .right
        }else if top.contains(location) {
            guard events.contains(.top) else { return }
            trigglePoint = .top
        }else if top.offsetBy(dx: 0, dy: height).contains(location) {
            guard events.contains(.bottom) else { return }
            trigglePoint = .bottom
        }else {
            guard events.contains(.translate) else { return }
            trigglePoint = .translate
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if trigglePoint == .none {
            return
        }
        guard let preLocation = touches.first?.previousLocation(in: self) else { return }
        guard let location = touches.first?.location(in: self) else { return }
        let offset = CGPoint.init(x: location.x - preLocation.x, y: location.y - preLocation.y)
        var resultRect: CGRect
        switch editStyle {
        case .fixableRatio(_):
            switch trigglePoint {
            case .translate:
                resultRect = CGRect.init(
                    x: frame.origin.x + offset.x, 
                    y: frame.origin.y + offset.y, 
                    width: frame.size.width, 
                    height: frame.size.height
                )
            case .leftTop:
                let center = CGPoint.init(x: frame.size.width/2, y: frame.size.height/2)
                let scale = (location - center).length/(preLocation - center).length
                let size = frame.size / 2 * (1 + scale)
                resultRect = CGRect.init(
                    x: frame.maxX - size.width, 
                    y: frame.maxY - size.height, 
                    width: size.width, 
                    height: size.height
                )
            case .rightTop:
                let center = CGPoint.init(x: frame.size.width/2, y: frame.size.height/2)
                let scale = (location - center).length/(preLocation - center).length
                let size = frame.size / 2 * (1 + scale)
                resultRect = CGRect.init(
                    x: frame.minX, 
                    y: frame.maxY - size.height, 
                    width: size.width, 
                    height: size.height
                )
            case .leftBottom:
                let center = CGPoint.init(x: frame.size.width/2, y: frame.size.height/2)
                let scale = (location - center).length/(preLocation - center).length
                let size = frame.size / 2 * (1 + scale)
                resultRect = CGRect.init(
                    x: frame.maxX - size.width, 
                    y: frame.minY, 
                    width: size.width, 
                    height: size.height
                )
            case .rightBottom:
                let center = CGPoint.init(x: frame.size.width/2, y: frame.size.height/2)
                let scale = (location - center).length/(preLocation - center).length
                let size = frame.size / 2 * (1 + scale)
                resultRect = CGRect.init(
                    x: frame.minX, 
                    y: frame.minY, 
                    width: size.width, 
                    height: size.height
                )
            default:
                return
            }
        case .flexible(_):
            switch trigglePoint {
            case .leftTop:
                resultRect = CGRect.init(
                    x: frame.origin.x + offset.x, 
                    y: frame.origin.y + offset.y, 
                    width: frame.size.width - offset.x, 
                    height: frame.size.height - offset.y
                )
            case .leftBottom:
                resultRect = CGRect.init(
                    x: frame.origin.x + offset.x, 
                    y: frame.origin.y, 
                    width: frame.size.width - offset.x, 
                    height: frame.size.height + offset.y
                )
            case .rightTop:
                resultRect = CGRect.init(
                    x: frame.origin.x, 
                    y: frame.origin.y + offset.y, 
                    width: frame.size.width + offset.x, 
                    height: frame.size.height - offset.y
                )
            case .rightBottom:
                resultRect = CGRect.init(
                    x: frame.origin.x, 
                    y: frame.origin.y, 
                    width: frame.size.width + offset.x, 
                    height: frame.size.height + offset.y
                )
            case .top:
                resultRect = CGRect.init(
                    x: frame.origin.x, 
                    y: frame.origin.y + offset.y, 
                    width: frame.size.width, 
                    height: frame.size.height - offset.y
                )
            case .bottom:
                resultRect = CGRect.init(
                    x: frame.origin.x, 
                    y: frame.origin.y, 
                    width: frame.size.width, 
                    height: frame.size.height + offset.y
                )
            case .left:
                resultRect = CGRect.init(
                    x: frame.origin.x + offset.x, 
                    y: frame.origin.y, 
                    width: frame.size.width - offset.x, 
                    height: frame.size.height
                )
            case .right:
                resultRect = CGRect.init(
                    x: frame.origin.x, 
                    y: frame.origin.y, 
                    width: frame.size.width + offset.x, 
                    height: frame.size.height
                )
            case .translate:
                resultRect = CGRect.init(
                    x: frame.origin.x + offset.x, 
                    y: frame.origin.y + offset.y, 
                    width: frame.size.width, 
                    height: frame.size.height
                )
            case .none:
                return
            }
        }
        if maxRegion.contains(resultRect) && resultRect.width >= minSize.width && resultRect.height >= minSize.height {
            frame = resultRect
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        trigglePoint = .none
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        trigglePoint = .none
    }
}

fileprivate class CropRegionView: YCFrameEditableView {
    
    var lineWidth: CGFloat = 1
    var cornerLineWidth: CGFloat = 2
    var cornerLineLength: CGFloat = 20
    var lineBackgroundColor = UIColor.white.cgColor
    var needGrid = true
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        
        ctx.saveGState()
        ctx.setBlendMode(.destinationIn)
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
        
        ctx.setStrokeColor(lineBackgroundColor)
        ctx.setLineWidth(lineWidth)
        ctx.stroke(rect.insetBy(dx: lineWidth/2, dy: lineWidth/2))
        
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        if needGrid {
            ctx.beginPath()
            //竖线
            for i in 1...2 {
                let start = CGPoint.init(x: minX + CGFloat(i)*rect.width/3, y: minY)
                let end = CGPoint.init(x: minX + CGFloat(i)*rect.width/3, y: maxY)
                ctx.move(to: start)
                ctx.addLine(to: end)
            }
            //横线
            for i in 1...2 {
                let start = CGPoint.init(x: minX, y: minY + CGFloat(i)*rect.height/3)
                let end = CGPoint.init(x: maxX, y: minY + CGFloat(i)*rect.height/3)
                ctx.move(to: start)
                ctx.addLine(to: end)
            }
            ctx.strokePath()
        }
        
        ctx.beginPath()
        let t = lineWidth + cornerLineWidth/2
        ctx.move(to: CGPoint.init(x: minX + t, y: minY + t + cornerLineLength))
        ctx.addLine(to: CGPoint.init(x: minX + t, y: minY + t))
        ctx.addLine(to: CGPoint.init(x: minX + t + cornerLineLength, y: minY + t))
        
        ctx.move(to: CGPoint.init(x: maxX - t, y: minY + t + cornerLineLength))
        ctx.addLine(to: CGPoint.init(x: maxX - t, y: minY + t))
        ctx.addLine(to: CGPoint.init(x: maxX - t - cornerLineLength, y: minY + t))
        
        ctx.move(to: CGPoint.init(x: maxX - t, y: maxY - t - cornerLineLength))
        ctx.addLine(to: CGPoint.init(x: maxX - t, y: maxY - t))
        ctx.addLine(to: CGPoint.init(x: maxX - t - cornerLineLength, y: maxY - t))
        
        ctx.move(to: CGPoint.init(x: minX + t, y: maxY - t - cornerLineLength))
        ctx.addLine(to: CGPoint.init(x: minX + t, y: maxY - t))
        ctx.addLine(to: CGPoint.init(x: minX + t + cornerLineLength, y: maxY - t))
        
        ctx.setLineWidth(cornerLineWidth)
        ctx.strokePath()
        
        ctx.restoreGState()
    }
}
