//
//  YCPhoto.swift
//  YCPhoto
//
//  Created by ldc on 2021/4/12.
//

import Foundation
import UIKit

public struct Config {
    
    struct Progress {
        
        static var showStatusClosure: ((String?) -> Void)?
        
        static var dismissClosure: (() -> Void)?
        
        static var showProgressClosure: ((Double, String?) -> Void)?
    }
    
    public static var boldFont: ((CGFloat) -> UIFont)?
    
    public static var mediumFont: ((CGFloat) -> UIFont)?
    
    public static var regularFont: ((CGFloat) -> UIFont)?
}
