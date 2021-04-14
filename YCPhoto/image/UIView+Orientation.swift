//
//  UIView+Orientation.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/13.
//

import UIKit

extension UIView {
    
    func monitorDeviceOrientation() -> Void {
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(self.deviceOrientationDidChange), 
            name: SJMotionOrientationManager.deviceOrientationDidChangeNotification, 
            object: nil
        )
    }
    
    @objc func deviceOrientationDidChange() {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.transform = SJMotionOrientationManager.shared.affineTransform
            })
        }
    }
}
