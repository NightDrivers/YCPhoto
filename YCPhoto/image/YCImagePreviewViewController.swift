//
//  YCImagePreviewViewController.swift
//  YCPhoto
//
//  Created by ldc on 2022/3/4.
//

import UIKit

public class YCImagePreviewViewController: UIViewController {
    
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBOutlet weak var cancelBtnWidth: NSLayoutConstraint!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    func configure() -> Void {
        
        let cancelText = "取消".yc_localized
        cancelBtn.setTitle(cancelText, for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtnWidth.constant = cancelText.drawWidth(with: cancelBtn.titleLabel!.font) + 20
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
}
