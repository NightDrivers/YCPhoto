//
//  PHImageManagerExtension.swift
//  HYEditor
//
//  Created by ldc on 2018/8/14.
//  Copyright © 2018年 swiftHY. All rights reserved.
//

import Foundation
import Photos
import BaseKitSwift

public extension PHImageManager {
    
    @discardableResult
    func loadIconImage(asset: PHAsset, targetSize: CGSize, closure: ((UIImage?) -> Void)?) -> PHImageRequestID {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .exact
        imageRequestOption.deliveryMode = .opportunistic
        imageRequestOption.isNetworkAccessAllowed = true
        return requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: imageRequestOption, resultHandler: { (image, _) in
            closure?(image)
        })
    }
}

public enum YCAssetRequestResult {
    case success(AVAsset)
    case isInCloud
    case system(Error)
    case unknown
}

public enum YCImageRequestResult {
    case success(UIImage)
    case isInCloud
    case system(Error)
    case unknown
}

public extension PHImageManager {
    
    func h_requestImage(asset: PHAsset, closure: @escaping (YCImageRequestResult) -> Void) -> Void {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .none
        imageRequestOption.deliveryMode = .highQualityFormat
        
        requestImageData(for: asset, options: imageRequestOption) { (data, uti, orientation, info) in
            
            if let data = data, var result = UIImage.init(data: data) {
                DispatchQueue.global().async {
                    result = result.maxSize(3072)
                    DispatchQueue.main.async {
                        closure(.success(result))
                    }
                }
            }else if let info = info {
                if let isCloud = info[PHImageResultIsInCloudKey] as? Bool, isCloud {
                    closure(.isInCloud)
                }else if let error = info[PHImageErrorKey] as? NSError {
                    closure(.system(error))
                }else {
                    closure(.unknown)
                }
            }else {
                closure(.unknown)
            }
        }
    }
    
    func h_requestCloudImage(asset: PHAsset, progressClosure: ((Double) -> Void)?, closure: @escaping (YCImageRequestResult) -> Void) -> Void {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .none
        imageRequestOption.deliveryMode = .highQualityFormat
        
        imageRequestOption.isNetworkAccessAllowed = true
        imageRequestOption.progressHandler = { (progress, error, stop, info) in
            DispatchQueue.main.async {
                if let error = error {
                    stop.pointee = ObjCBool.init(true)
                    closure(.system(error))
                }else {
                    progressClosure?(progress)
                }
            }
        }
        
        requestImageData(for: asset, options: imageRequestOption) { (data, uti, orientation, info) in
            
            if let data = data, var result = UIImage.init(data: data) {
                DispatchQueue.global().async {
                    result = result.maxSize(3072)
                    DispatchQueue.main.async {
                        closure(.success(result))
                    }
                }
            }else if let info = info {
                if let error = info[PHImageErrorKey] as? NSError {
                    closure(.system(error))
                }else {
                    closure(.unknown)
                }
            }else {
                closure(.unknown)
            }
        }
    }
    
    func h_requestAVAsset(asset: PHAsset, closure: @escaping (YCAssetRequestResult) -> Void) -> Void {
        
        let options = PHVideoRequestOptions()
        requestAVAsset(forVideo: asset, options: options, resultHandler: { (result, _, info) in
            
            let excuteClosure = {
                if let result = result {
                    closure(.success(result))
                }else if let info = info {
                    if let isCloud = info[PHImageResultIsInCloudKey] as? Bool, isCloud {
                        closure(.isInCloud)
                    }else if let error = info[PHImageErrorKey] as? NSError {
                        closure(.system(error))
                    }else {
                        closure(.unknown)
                    }
                }else {
                    closure(.unknown)
                }
            }
            
            if Thread.isMainThread {
                excuteClosure()
            }else {
                DispatchQueue.main.async {
                    excuteClosure()
                }
            }
        })
    }
    
    func h_requestCloudAVAsset(asset: PHAsset, progressClosure: ((Double) -> Void)?, closure: @escaping (YCAssetRequestResult) -> Void) -> Void {
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { (progress, error, stop, info) in
            
            DispatchQueue.main.async {
                if let error = error {
                    stop.pointee = ObjCBool.init(true)
                    closure(.system(error))
                }else {
                    progressClosure?(progress)
                }
            }
        }
        requestAVAsset(forVideo: asset, options: options, resultHandler: { (result, _, info) in
            
            DispatchQueue.main.async {
                if let result = result {
                    closure(.success(result))
                }else if let info = info {
                    if let error = info[PHImageErrorKey] as? NSError {
                        closure(.system(error))
                    }else {
                        closure(.unknown)
                    }
                }else {
                    closure(.unknown)
                }
            }
        })
    }
}

public enum YCResult<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

public extension UIViewController {
    
    func requestImage(asset: PHAsset, showActivity: Bool = true, closure: @escaping (YCResult<UIImage, () -> Void>) -> Void) -> Void {
        
        if showActivity {
            Config.Progress.showStatusClosure?("图片加载中...".yc_localized)
        }
        PHImageManager.default().h_requestImage(asset: asset, closure: {
            if showActivity {
                Config.Progress.dismissClosure?()
            }
            switch $0 {
            case .success(let image):
                closure(.success(image))
            case .isInCloud:
                self.bk_presentDecisionAlertController(
                    title: "提示".yc_localized, 
                    message: "是否下载iCloud图片?".yc_localized, 
                    decisionTitle: "确定".yc_localized, 
                    decisionClosure: { (_) in
                        self.requestCloudImage(asset: asset, closure: closure)
                    }, cancelClosure: { _ in
                        closure(.failure({}))
                    })
            case .system(let error):
                closure(.failure({ 
                    let error = error as NSError
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: String.init(format: "图片加载失败-%@-%i".yc_localized, error.domain, error.code))
                }))
            case .unknown:
                closure(.failure({ 
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: "图片加载失败-未知错误".yc_localized)
                }))
            }
        })
    }
    
    func requestCloudImage(asset: PHAsset, closure: @escaping (YCResult<UIImage, () -> Void>) -> Void) -> Void {
        
        Config.Progress.showProgressClosure?(0, "图片下载中...".yc_localized)
        PHImageManager.default().h_requestCloudImage(asset: asset, progressClosure: {
            Config.Progress.showProgressClosure?($0, "图片下载中...".yc_localized)
        }, closure: {
            Config.Progress.dismissClosure?()
            switch $0 {
            case .success(let image):
                closure(.success(image))
            case .isInCloud:
                closure(.failure({ }))
            case .system(let error):
                closure(.failure({ 
                    let error = error as NSError
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: String.init(format: "图片下载失败-%@-%i".yc_localized, error.domain, error.code))
                }))
            case .unknown:
                closure(.failure({ 
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: "图片下载失败-未知错误".yc_localized)
                }))
            }
        })
    }
    
    func h_requestAVAsset(asset: PHAsset, showActivity: Bool = true, closure: @escaping (YCResult<AVAsset, () -> Void>) -> Void) -> Void {
        
        if showActivity {
            Config.Progress.showStatusClosure?("视频加载中...".yc_localized)
        }
        PHImageManager.default().h_requestAVAsset(asset: asset, closure: {
            if showActivity {
                Config.Progress.dismissClosure?()
            }
            switch $0 {
            case .success(let image):
                closure(.success(image))
            case .isInCloud:
                self.bk_presentDecisionAlertController(
                    title: "提示".yc_localized, 
                    message: "是否下载iCloud视频?".yc_localized, 
                    decisionTitle: "确定".yc_localized, 
                    decisionClosure: { (_) in
                        self.h_requestCloudAVAsset(asset: asset, closure: closure)
                    }, cancelClosure: { _ in
                        closure(.failure({ }))
                    })
            case .system(let error):
                closure(.failure({ 
                    let error = error as NSError
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: String.init(format: "视频加载失败-%@-%i".yc_localized, error.domain, error.code))
                }))
            case .unknown:
                closure(.failure({ 
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: "视频加载失败-未知错误".yc_localized)
                }))
            }
        })
    }
    
    func h_requestCloudAVAsset(asset: PHAsset, closure: @escaping (YCResult<AVAsset, () -> Void>) -> Void) -> Void {
        
        Config.Progress.showProgressClosure?(0, "视频下载中...".yc_localized)
        PHImageManager.default().h_requestCloudAVAsset(asset: asset, progressClosure: {
            Config.Progress.showProgressClosure?($0, "视频下载中...".yc_localized)
        }, closure: {
            Config.Progress.dismissClosure?()
            switch $0 {
            case .success(let image):
                closure(.success(image))
            case .isInCloud:
                closure(.failure({ }))
            case .system(let error):
                closure(.failure({ 
                    let error = error as NSError
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: String.init(format: "视频下载失败-%@-%i".yc_localized, error.domain, error.code))
                }))
            case .unknown:
                closure(.failure({ 
                    self.bk_presentWarningAlertController(title: "提示".yc_localized, message: "视频下载失败-未知错误".yc_localized)
                }))
            }
        })
    }
}
