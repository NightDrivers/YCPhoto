//
//  ViewController.swift
//  Example
//
//  Created by ldc on 2021/4/14.
//

import UIKit
import YCPhoto
import SVProgressHUD
import Photos

class YCPhotosSource {
    
    let collections: [PHAssetCollection]
    let fetchOptions: PHFetchOptions
    
    init(fetchOptions: PHFetchOptions) {
        self.fetchOptions = fetchOptions
        var items = [PHAssetCollection]()
        let smartCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartCollections.enumerateObjects { (collection, index, finished) in
            
            switch collection.assetCollectionSubtype {
            case .smartAlbumAllHidden,.smartAlbumVideos:
                break
            default:
                if collection.assetCollectionSubtype.rawValue == 1000000201 {
                    //最近删除
                    return
                }
                items.append(collection)
            }
        }
        
        let topLevelCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        topLevelCollections.enumerateObjects { (collection, index, finished) in
            if let collection = collection as? PHAssetCollection {
                items.append(collection)
            }
        }
        collections = items
    }
}

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
        let start = CFAbsoluteTimeGetCurrent()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // 1 图片 2 视频 3 音频
        options.predicate = NSPredicate.init(format: "mediaType = 1")
        
        let smartAlbumCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartAlbumCollections.enumerateObjects { (collection, index, finished) in
            
            switch collection.assetCollectionSubtype {
            
            case .smartAlbumAllHidden,.smartAlbumVideos:
                break
            default:
                if collection.assetCollectionSubtype.rawValue == 1000000201 {
                    //最近删除
                    return
                }
            }
        }
        
        let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        
        userCollections.enumerateObjects { (collection, index, finished) in
            
            if let unwarpedCollection = collection as? PHAssetCollection {
                
            }
        }
        let end = CFAbsoluteTimeGetCurrent()
        print("耗时: \(end - start)s")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        let temp = YCImagePickerViewController.init(style: .single(needCamera: false))
        let temp = YCImagePickerViewController.init(style: .single(needCamera: true, cropMode: .noCrop))
//        let temp = YCCameraViewController.init(with: .flexibleCrop(1), supply: nil)
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

