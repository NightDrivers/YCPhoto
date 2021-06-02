//
//  YCPhoto.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/12.
//

import Foundation
import UIKit

public struct Config {
    
    public struct Progress {
        
        public static var showStatusClosure: ((String?) -> Void)?
        
        public static var dismissClosure: (() -> Void)?
        
        public static var showProgressClosure: ((Double, String?) -> Void)?
    }
    
    public static var boldFont: ((CGFloat) -> UIFont)?
    
    public static var mediumFont: ((CGFloat) -> UIFont)?
    
    public static var regularFont: ((CGFloat) -> UIFont)?
}

func getBundleImage(_ name: String) -> UIImage? {
    
    guard let url = FrameworkBundle.url(forResource: "YCPhoto", withExtension: "bundle") else { return nil }
    guard let resourceBundle = Bundle.init(url: url) else { return nil }
    guard let imagePath = resourceBundle.path(forResource: name, ofType: "png") else { return nil }
    return UIImage.init(contentsOfFile: imagePath)
}

var FrameworkBundle: Bundle = {
    
    return Bundle.init(for: YCImagePickerViewController.self)
}()

func ViewControllerFromStoryboard(file name: String, iden: String) -> UIViewController {
    
    return UIStoryboard.init(name: name, bundle: FrameworkBundle).instantiateViewController(withIdentifier: iden)
}
