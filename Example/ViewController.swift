//
//  ViewController.swift
//  Example
//
//  Created by ldc on 2021/4/14.
//

import UIKit
import YCPhoto
import SVProgressHUD

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Config.Progress.showProgressClosure = { SVProgressHUD.showProgress(Float($0), status: $1) }
        Config.Progress.showStatusClosure = { SVProgressHUD.show(withStatus: $0) }
        Config.Progress.dismissClosure = { SVProgressHUD.dismiss() }
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let temp = YCImagePickerViewController.init(style: .multi(maxCount: 9))
        temp.didPickPhotoClosure = { [weak temp] in
            let image = $0[0]
            temp?.dismiss(animated: true, completion: {
                self.imageView.image = image
            })
        }
        self.show(temp, sender: nil)
    }

    lazy var imageView: UIImageView = {
        let temp = UIImageView()
        temp.contentMode = .scaleAspectFit
        view.addSubview(temp)
        return temp
    }()
}

