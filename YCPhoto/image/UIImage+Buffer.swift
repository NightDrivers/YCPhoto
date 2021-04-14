//
//  UIImage+Buffer.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/13.
//

import UIKit
import CoreMedia

public extension UIImage {
    
    static func image(sample buffer: CMSampleBuffer, device orientation: UIDeviceOrientation) -> UIImage {
        
        return image(pixel: CMSampleBufferGetImageBuffer(buffer)!, device: orientation)
    }
    
    static func image(pixel buffer: CVPixelBuffer, device orientation: UIDeviceOrientation) -> UIImage {
        
        let imageOrientation: UIImage.Orientation
        switch orientation {
        case .portrait:
            imageOrientation = .right
        case .landscapeRight:
            imageOrientation = .down
        case .portraitUpsideDown:
            imageOrientation = .left
        default:
            imageOrientation = .up
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.init(rawValue: 0))
        let base = CVPixelBufferGetBaseAddress(buffer)!
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext.init(data: base, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGImageByteOrderInfo.order32Little.rawValue)!
        let cgImage = ctx.makeImage()!
        let image = UIImage.init(cgImage: cgImage, scale: 1, orientation: imageOrientation)
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.init(rawValue: 0))
        return image
    }
}

public extension UIImage {
    
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

public extension UIImage {
    
    func sub(_ ratioRect: CGRect) -> UIImage {
        
        let rect = CGRect.init(x: self.pixelWidth*ratioRect.origin.x, 
                               y: self.pixelHeight*ratioRect.origin.y, 
                               width: self.pixelWidth*ratioRect.width, 
                               height: self.pixelHeight*ratioRect.height)
        return self.crop(pixelRect: rect)
    }
}
