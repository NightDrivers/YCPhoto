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

private extension UIImage {
    
    func maxSize(_ pixelCount: CGFloat) -> UIImage {
        
        var scale: CGFloat = 1
        if pixelWidth > pixelCount || pixelHeight > pixelCount {
            let maxPixel = max(pixelWidth, pixelHeight)
            scale = pixelCount/maxPixel
        }
        let size = CGSize.init(width: floor(pixelWidth*scale), height: floor(pixelHeight*scale))
        let rect = CGRect.init(origin: .zero, size: size)
        UIGraphicsBeginImageContext(size)
        UIColor.white.setFill()
        UIRectFill(rect)
        draw(in: rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }
}

extension PHImageManager {
    
    func loadHighQualityImageIgnoreiCloud(asset: PHAsset, requestActivityIndicatorVisible: Bool = true ,completeClosure: @escaping (UIImage?) -> Void) -> Void {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .none
        imageRequestOption.deliveryMode = .highQualityFormat
        
        if requestActivityIndicatorVisible {
            Config.Progress.showStatusClosure?("图片加载中...".localized)
        }
        requestImageData(for: asset, options: imageRequestOption) { (data, uti, orientation, info) in
            
            if let info = info, let isCloud = info[PHImageResultIsInCloudKey] as? Bool, isCloud {
                
                if requestActivityIndicatorVisible {
                    Config.Progress.dismissClosure?()
                }
                completeClosure(nil)
            }else {
                if let unwrappedData = data, var result = UIImage.init(data: unwrappedData) {
                    DispatchQueue.global().async {
                        result = result.maxSize(3072)
                        DispatchQueue.main.async {
                            if requestActivityIndicatorVisible {
                                Config.Progress.dismissClosure?()
                            }
                            completeClosure(result)
                        }
                    }
                }else {
                    if requestActivityIndicatorVisible {
                        Config.Progress.dismissClosure?()
                    }
                    completeClosure(nil)
                }
            }
        }
    }
    
    func loadHighQualityImage(
        asset: PHAsset, 
        completeClosure: @escaping (UIImage?) -> Void,
        requestActivityIndicatorVisible: Bool = true,
        target: UIViewController? = KeyWindow?.rootViewController
    ) -> Void {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .none
        imageRequestOption.deliveryMode = .highQualityFormat
        
        if requestActivityIndicatorVisible {
            Config.Progress.showStatusClosure?("图片加载中...".localized)
        }
        requestImageData(for: asset, options: imageRequestOption) { (data, uti, orientation, info) in

            if let info = info, let isCloud = info[PHImageResultIsInCloudKey] as? Bool, isCloud {

                if requestActivityIndicatorVisible {
                    Config.Progress.dismissClosure?()
                }
                target?.bk_presentDecisionAlertController(title: "提示".localized, message: "是否下载iCloud图片?".localized, decisionTitle: "确定".localized, decisionClosure: { (_) in
                    self.loadHighQualityiCloudImage(asset: asset, closure: completeClosure, target: target)
                }, cancelClosure: { (_) in
                    completeClosure(nil)
                })
            }else {
                if let unwrappedData = data, var result = UIImage.init(data: unwrappedData) {
                    DispatchQueue.global().async {
                        result = result.maxSize(3072)
                        DispatchQueue.main.async {
                            if requestActivityIndicatorVisible {
                                Config.Progress.dismissClosure?()
                            }
                            completeClosure(result)
                        }
                    }
                }else {
                    if requestActivityIndicatorVisible {
                        Config.Progress.dismissClosure?()
                    }
                    var msg = "请检查网络是否可用".localized
                    #if NeedLog
                    if let error = info?[PHImageErrorKey] as? NSError {
                        msg = "--\(error)"
                    }
                    #endif
                    target?.bk_presentWarningAlertController(title: "提示".localized, message: "加载图片失败: ".localized + msg, closure: { (_) in
                        completeClosure(nil)
                    })
                }
            }
        }
    }
    
    private func loadHighQualityiCloudImage(
        asset: PHAsset, 
        closure: @escaping (UIImage?) -> Void,
        target: UIViewController? = KeyWindow?.rootViewController
    ) {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .none
        imageRequestOption.deliveryMode = .highQualityFormat
        
        imageRequestOption.isNetworkAccessAllowed = true
        imageRequestOption.progressHandler = { (progress, error, stop, info) in
            DispatchQueue.main.async {
                if error != nil {
                    Config.Progress.dismissClosure?()
                    stop.pointee = ObjCBool.init(true)
                }else {
                    if progress == 1 {
                        Config.Progress.dismissClosure?()
                    }else {
                        Config.Progress.showProgressClosure?(progress, "网络获取图片中...".localized)
                    }
                }
            }
        }
        
        requestImageData(for: asset, options: imageRequestOption) { (data, uti, orientation, info) in

            if let unwrappedData = data, var result = UIImage.init(data: unwrappedData) {
                Config.Progress.showStatusClosure?("图片处理中...".localized)
                DispatchQueue.global().async {
                    result = result.maxSize(3072)
                    DispatchQueue.main.async {
                        Config.Progress.dismissClosure?()
                        closure(result)
                    }
                }
            }else {
                var msg = "请检查网络是否可用".localized
                #if NeedLog
                if let error = info?[PHImageErrorKey] as? NSError {
                    msg = "--\(error)"
                }
                #endif
                target?.bk_presentWarningAlertController(title: "提示".localized, message: "加载图片失败: ".localized + msg, closure: { (_) in
                    closure(nil)
                })
            }
        }
    }
    
    func loadIconImage(asset: PHAsset, targetSize: CGSize, closure: ((UIImage?) -> Void)?) -> Void {
        
        let imageRequestOption = PHImageRequestOptions()
        imageRequestOption.resizeMode = .exact
        imageRequestOption.deliveryMode = .opportunistic
        imageRequestOption.isNetworkAccessAllowed = true
        requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: imageRequestOption, resultHandler: { (image, _) in
            closure?(image)
        })
    }
    
    func loadAV(asset: PHAsset, closure: @escaping (AVAsset?) -> Void) -> Void {
        
        let options = PHVideoRequestOptions()
        requestAVAsset(forVideo: asset, options: options, resultHandler: { (result, audioMix, info) in
            
            let excuteClosure = {
                if let result = result {
                    closure(result)
                }else if let info = info, let isCloud = info[PHImageResultIsInCloudKey] as? Bool, isCloud {
                    KeyWindow?.rootViewController?.bk_presentDecisionAlertController(title: "提示".localized, message: "是否下载iCloud视频?".localized, decisionTitle: "确定".localized, decisionClosure: { (_) in
                        self.loadiCloudAV(asset: asset, closure: closure)
                    }, cancelClosure: { (_) in
                        closure(nil)
                    })
                }else {
                    var msg = "请检查网络是否可用".localized
                    #if NeedLog
                    if let error = info?[PHImageErrorKey] as? NSError {
                        msg = "--\(error)"
                    }
                    #endif
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".localized, message: "视频加载失败: ".localized + msg, closure: { (_) in
                        closure(nil)
                    })
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
    
    private func loadiCloudAV(asset: PHAsset, closure: @escaping (AVAsset?) -> Void) -> Void {
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { (progress, error, stop, info) in
            
            DispatchQueue.main.async {
                if error != nil {
                    KeyWindow?.rootViewController?.bk_presentWarningAlertController(title: "提示".localized, message: "获取iCloud视频失败,请检查网络状态".localized, closure: { (_) in
                        closure(nil)
                    })
                    Config.Progress.dismissClosure?()
                    stop.pointee = ObjCBool.init(true)
                }else {
                    if progress == 1 {
                        Config.Progress.dismissClosure?()
                    }else {
                        Config.Progress.showProgressClosure?(progress, "网络获取视频中...".localized)
                    }
                }
            }
        }
        requestAVAsset(forVideo: asset, options: options, resultHandler: { (result, audioMix, info) in
            guard let result = result else { return }
            DispatchQueue.main.async {
                closure(result)
            }
        })
    }
}

extension PHPhotoLibrary {
    
    static func requestAssetsForVideo() -> PHFetchResult<PHAsset> {
        
        let fetchOption = PHFetchOptions()
        fetchOption.predicate = NSPredicate.init(format: "duration >= 5 and duration <= 600")
        fetchOption.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .video, options: fetchOption)
        return result
    }
}

extension PHImageManager {
    
    enum AVAssetRequestResult {
        case success(AVAsset)
        case isInCloud
        case system(Error)
        case unknown
    }
    
    enum ImageRequestResult {
        case success(UIImage)
        case isInCloud
        case system(Error)
        case unknown
    }
    
    func h_requestImage(asset: PHAsset, closure: @escaping (ImageRequestResult) -> Void) -> Void {
        
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
    
    func h_requestCloudImage(asset: PHAsset, progressClosure: ((Double) -> Void)?, closure: @escaping (ImageRequestResult) -> Void) -> Void {
        
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
            }
        }
    }
    
    func h_requestAVAsset(asset: PHAsset, closure: @escaping (AVAssetRequestResult) -> Void) -> Void {
        
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
    
    func h_requestCloudAVAsset(asset: PHAsset, progressClosure: ((Double) -> Void)?, closure: @escaping (AVAssetRequestResult) -> Void) -> Void {
        
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
            
            guard let result = result else { return }
            DispatchQueue.main.async {
                closure(.success(result))
            }
        })
    }
}
