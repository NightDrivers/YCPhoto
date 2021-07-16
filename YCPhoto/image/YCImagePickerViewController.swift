//
//  YCImagePickerHostViewController.swift
//  HPrint
//
//  Created by ldc on 2020/3/20.
//  Copyright © 2020 WuYB. All rights reserved.
//

import UIKit
import Photos
import BaseKitSwift

public class YCImagePickerViewController: UINavigationController {
    
    public var didPickPhotoClosure: (([UIImage]) -> Void)?
    
    private let imagePickerHostViewController: YCImagePickerHostViewController
    
    public init(style: YCImagePickerStyle) {
        self.imagePickerHostViewController = ViewControllerFromStoryboard(file: "image", iden: "image.picker") as! YCImagePickerHostViewController
        self.imagePickerHostViewController.style = style
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.setNavigationBarHidden(true, animated: false)
        self.setViewControllers([self.imagePickerHostViewController], animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePickerHostViewController.didPickPhotoClosure = { [weak self] in
            self?.didPickPhotoClosure?($0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct YCAssetCollection: Equatable {
    let collection: PHAssetCollection
    let fetchResult: PHFetchResult<PHAsset>
}

func fetchAssetCollections() -> [YCAssetCollection] {
    
    var collections = [YCAssetCollection]()
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
            let result = PHAsset.fetchAssets(in: collection, options: options)
            if result.count > 0 {
                let temp = YCAssetCollection.init(collection: collection, fetchResult: result)
                collections.append(temp)
            }
        }
    }
    
    let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
    
    userCollections.enumerateObjects { (collection, index, finished) in
        
        if let unwarpedCollection = collection as? PHAssetCollection {
            let result = PHAsset.fetchAssets(in: unwarpedCollection, options: options)
            if result.count > 0 {
                let temp = YCAssetCollection.init(collection: unwarpedCollection, fetchResult: result)
                collections.append(temp)
            }
        }
    }
    collections.sort { (collection1, collection2) -> Bool in
        return collection1.fetchResult.count > collection2.fetchResult.count
    }
    return collections
}

public enum YCImagePickerStyle {
    case single(needCamera: Bool)
    case multi(maxCount: Int)
    case singleForCrop(ratio: CGFloat)
    
    var needCamera: Bool {
        
        switch self {
        case .single(needCamera: let needCamera):
            if needCamera {
                return true
            }else {
                return false
            }
        case .multi(maxCount: _):
            return false
        case .singleForCrop(ratio: _):
            return false
        }
    }
    
    var maxCount: Int {
        
        switch self {
        case .single(needCamera: _):
            return 1
        case .multi(maxCount: let count):
            return count
        case .singleForCrop(ratio: _):
            return 1
        }
    }
}

class YCImagePickerHostViewController: UIViewController {
    
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var multiSelectCompleteButton: UIButton!
    
    @IBOutlet weak var collectionSwitchButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var effectView: UIVisualEffectView!
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let imageManager = PHCachingImageManager()
    
    fileprivate var previousPreheatRect = CGRect.zero
    
    var assetItemSize: CGSize { collectionViewFlowLayout.itemSize }
    
    var imageCache = [Int : UIImage]()
    
    var style: YCImagePickerStyle = .single(needCamera: false)
    
    var collections: [YCAssetCollection] = [] {
        
        didSet {
            tableView.reloadData()
        }
    }
    var currentAssetCollection: YCAssetCollection? {
        
        didSet {
            self.collectionSwitchButton.setTitle(currentAssetCollection?.collection.localizedTitle, for: .normal)
            self.imageCache = [:]
            self.collectionView.reloadData()
            self.updatePickedImageCount()
        }
    }
    
    var didPickPhotoClosure: (([UIImage]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        PHPhotoLibrary.shared().register(self)
        configure()
        
        self.collections = fetchAssetCollections()
        if self.collections.count > 0 {
            self.currentAssetCollection = self.collections[0]
        }
    }
    
    func configure() -> Void {
        
        updatePickedImageCount()
        collectionSwitchButton.setTitle(currentAssetCollection?.collection.localizedTitle, for: .normal)
        collectionSwitchButton.setImage(getBundleImage("btn_icon_arrow_down"), for: .normal)
        collectionSwitchButton.setImage(getBundleImage("btn_icon_arrow_up"), for: .selected)
        closeButton.setImage(getBundleImage("btn_close"), for: .normal)
        
        let w: CGFloat
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            w = floor((UIScreen.main.bounds.width - 4)/4)
        default:
            w = floor((UIScreen.main.bounds.width - 3)/3)
        }
        collectionViewFlowLayout.itemSize = CGSize.init(width: w, height: w)
        switch style {
        case .multi(maxCount: _):
            collectionView.allowsMultipleSelection = true
            multiSelectCompleteButton.isHidden = false
        default:
            collectionView.allowsMultipleSelection = false
            multiSelectCompleteButton.isHidden = true
        }
        
        view.addSubview(effectView)
        effectView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(topView.snp.bottom)
        }
        effectView.isHidden = true
    }
    
    func updatePickedImageCount() -> Void {
        
        switch style {
        case .multi(maxCount: let count):
            let selectedCount = collectionView.indexPathsForSelectedItems != nil ? collectionView.indexPathsForSelectedItems!.count : 0
            self.multiSelectCompleteButton.setTitle(String.init(format: "%i/%i完成".yc_localized, selectedCount, count), for: .normal)
        default:
            break
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionSwitchButton.layoutImageTitleHolizontallyCenterReverse(contentSpace: 5)
    }
    
    override var prefersStatusBarHidden: Bool { false }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension YCImagePickerHostViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.async {
            self.collections = fetchAssetCollections()
            if self.collections.count > 0 {
                if let temp = self.currentAssetCollection {
                    if let change = changeInstance.changeDetails(for: temp.fetchResult) {
//                        print(change.insertedIndexes)
//                        print(change.removedIndexes)
//                        print(change.changedIndexes)
//                        print(change.fetchResultBeforeChanges)
//                        print(change.fetchResultAfterChanges)
//                        print(change.insertedObjects)
//                        print(change.removedObjects)
//                        print(change.changedObjects)
//                        print(change.hasMoves)
//                        print("------")
                        if change.insertedObjects.count == 0 && change.removedObjects.count == 0 && change.fetchResultBeforeChanges.count == change.fetchResultAfterChanges.count {
                            //当前图片集合没有增减不做处理
                            return
                        }
                        self.currentAssetCollection = self.collections[0]
                    }
                }else {
                    self.currentAssetCollection = self.collections[0]
                }
            }else {
                self.currentAssetCollection = YCAssetCollection.init(collection: PHAssetCollection(), fetchResult: PHFetchResult<PHAsset>())
            }
        }
    }
}

extension YCImagePickerHostViewController {
    
    @IBAction func collectionSwitchButtonAction() {
        
        collectionSwitchButton.isSelected = !collectionSwitchButton.isSelected
        let isHidden = !effectView.isHidden
        effectView.alpha = isHidden ? 1 : 0
        effectView.isHidden = false
        UIView.animate(withDuration: 0.25, animations: { 
            self.effectView.alpha = isHidden ? 0 : 1
        }) { (finished) in
            self.effectView.isHidden = isHidden
            self.effectView.alpha = 1
        }
        
    }
    
    @IBAction func closeAction(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func multiSelectCompleteAction() {
        
        switch style {
        case .multi(maxCount: _):
            var result = [UIImage]()
            if let selectIndexPaths = collectionView.indexPathsForSelectedItems {
                for indexPath in selectIndexPaths.sorted(by: { $0.row < $1.row }) {
                    if let image = imageCache[indexPath.item] {
                        result.append(image)
                    }
                }
            }
            if result.count == 0 {
                return
            }
            self.didPickPhotoClosure?(result)
        default:
            break
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension YCImagePickerHostViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let temp = currentAssetCollection else { return style.needCamera ? 1 : 0 }
        return style.needCamera ? temp.fetchResult.count + 1 : temp.fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iden", for: indexPath) as! YCImageAssetCollectionViewCell
        switch style {
        case .multi(maxCount: _):
            cell.selectable = true
        case .single(needCamera: _):
            cell.selectable = false
        case .singleForCrop(ratio: _):
            cell.selectable = false
        }
        let needCamera = style.needCamera
        if needCamera && indexPath.item == 0 {
            cell.imageView.backgroundColor = UIColor.random
            cell.imageView.image = nil
        }else {
            guard let temp = currentAssetCollection else { return cell }
            let index = needCamera ? indexPath.item - 1 : indexPath.item
            let asset = temp.fetchResult[index]
            imageManager.loadIconImage(asset: asset, targetSize: assetItemSize * UIScreen.main.scale, closure: { (image) in
                cell.imageView.image = image
            })
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        switch style {
        case .multi(maxCount: let maxCount):
            if let count = collectionView.indexPathsForSelectedItems?.count {
                if count >= maxCount {
                    return false
                }
            }
        default:
            break
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch style {
        case .multi(maxCount: _):
            guard let temp = currentAssetCollection else { return }
            let asset = temp.fetchResult[indexPath.item]
            self.requestImage(asset: asset, showActivity: false, closure: {
                switch $0 {
                case .success(let image):
                    self.imageCache[indexPath.item] = image
                    self.updatePickedImageCount()
                case .failure(let closure):
                    collectionView.deselectItem(at: indexPath, animated: true)
                    closure()
                }
            })
        case .single(needCamera: let needCamera):
            collectionView.deselectItem(at: indexPath, animated: true)
            if needCamera && indexPath.item == 0 {
                //打开摄像头
            }else {
                let index = needCamera ? indexPath.item - 1 : indexPath.item
                guard let temp = currentAssetCollection else { return }
                let asset = temp.fetchResult[index]
                self.requestImage(asset: asset, closure: {
                    switch $0 {
                    case .success(let image):
                        self.didPickPhotoClosure?([image])
                    case .failure(let closure):
                        closure()
                    }
                })
            }
        case .singleForCrop(ratio: let ratio):
            collectionView.deselectItem(at: indexPath, animated: true)
            let index = indexPath.item
            guard let temp = currentAssetCollection else { return }
            let asset = temp.fetchResult[index]
            self.requestImage(asset: asset, closure: {
                switch $0 {
                case .success(let image):
                    let temp = YCImageCropViewController.init(image: image, cropMode: .fixableCrop(ratio), rotatable: true)
                    temp.didCropClosure = { [weak temp] (image, _) in
                        let image = image
                        temp?.dismiss(animated: false, completion: {
                            self.didPickPhotoClosure?([image])
                        })
                    }
                    self.present(temp, animated: false, completion: nil)
                case .failure(let closure):
                    closure()
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        switch style {
        case .multi(maxCount: _):
            self.imageCache.removeValue(forKey: indexPath.item)
            self.updatePickedImageCount()
        default:
            break
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard let temp = currentAssetCollection else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > collectionView.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .filter({ style.needCamera ? $0.item != 0 : true })
            .map { style.needCamera ? temp.fetchResult.object(at: $0.item - 1) : temp.fetchResult.object(at: $0.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .filter({ style.needCamera ? $0.item != 0 : true })
            .map { style.needCamera ? temp.fetchResult.object(at: $0.item - 1) : temp.fetchResult.object(at: $0.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: assetItemSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: assetItemSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

class YCImageAssetCollectionViewCell: UICollectionViewCell {
    
    var requestID: PHImageRequestID?
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    override var isSelected: Bool {
        
        didSet {
            selectedImageView.image = isSelected ? getBundleImage( "selection_icon") : getBundleImage( "unselected_icon")
        }
    }
    
    var selectable: Bool = false {
        
        didSet {
            selectedImageView.isHidden = !selectable
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        imageView.clipsToBounds = true
        selectedImageView.isHidden = true
        selectedImageView.image = getBundleImage( "unselected_icon")
    }
}

extension YCImagePickerHostViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return collections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let iden = "iden"
        let cell = tableView.dequeueReusableCell(withIdentifier: iden) as! YCAssetCollectionTableCell
        let collection = collections[indexPath.row]
        cell.nameLabel.text = collection.collection.localizedTitle
        cell.countLabel.text = "\(collection.fetchResult.count)"
        if let asset = collection.fetchResult.firstObject {
            PHImageManager.default().loadIconImage(asset: asset, targetSize: CGSize.init(width: 60, height: 60)*UIScreen.main.scale, closure: { (image) in
                cell.reprImageView.image = image
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.collectionSwitchButtonAction()
        let collection = collections[indexPath.row]
        guard collection != self.currentAssetCollection else {
            return
        }
        self.currentAssetCollection = collection
    }
}

class YCAssetCollectionTableCell: UITableViewCell {
    
    @IBOutlet weak var reprImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        reprImageView.clipsToBounds = true
    }
}
