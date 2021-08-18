//
//  UIView+Orientation.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/13.
//

import UIKit

public extension UIView {
    
    public func monitorDeviceOrientation() -> Void {
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.deviceOrientationDidChange), 
            name: YCMotionOrientationManager.deviceOrientationDidChangeNotification, 
            object: nil
        )
    }
    
    @objc func deviceOrientationDidChange(notification: Notification) {
        
        guard let orientationManager = notification.object as? YCMotionOrientationManager else { return }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.transform = orientationManager.affineTransform
            })
        }
    }
}
