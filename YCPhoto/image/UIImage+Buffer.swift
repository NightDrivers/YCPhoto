//
//  UIImage+Buffer.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/13.
//

import UIKit
import CoreMedia

extension UIImage {
    
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
