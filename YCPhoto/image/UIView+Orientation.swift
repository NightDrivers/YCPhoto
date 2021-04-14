//
//  UIView+Orientation.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/13.
//

import UIKit

public extension UIView {
    
    func monitorDeviceOrientation() -> Void {
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.deviceOrientationDidChange), 
            name: YCMotionOrientationManager.deviceOrientationDidChangeNotification, 
            object: nil
        )
    }
    
    @objc func deviceOrientationDidChange() {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.transform = YCMotionOrientationManager.shared.affineTransform
            })
        }
    }
}
