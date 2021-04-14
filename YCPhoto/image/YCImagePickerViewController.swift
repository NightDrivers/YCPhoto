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

class YCImagePickerViewController: UINavigationController {
    
    var didPickPhotoClosure: (([UIImage]) -> Void)?
    
    private let imagePickerHostViewController: YCImagePickerHostViewController
    
    init(style: YCImagePickerStyle) {
        self.imagePickerHostViewController = YCImagePickerHostViewController.init(style: style)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.setNavigationBarHidden(true, animated: false)
        self.setViewControllers([self.imagePickerHostViewController], animated: true)
    }
    
    override func viewDidLoad() {
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

enum YCImagePickerStyle {
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

private class YCImagePickerHostViewController: UIViewController {
    
    let style: YCImagePickerStyle
    var collections: [YCAssetCollection] = [] {
        didSet {
            assetCollectionPickerView.collections = collections
        }
    }
    var pickedAssetCollection: YCAssetCollection? {
        
        didSet {
            self.collectionSwitchButton.setTitle(pickedAssetCollection?.collection.localizedTitle, for: .normal)
            self.imageAssetsView.collection = pickedAssetCollection
        }
    }
    
    var didPickPhotoClosure: (([UIImage]) -> Void)?
    
    init(style: YCImagePickerStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        self.collections = fetchAssetCollections()
        if self.collections.count > 0 {
            self.pickedAssetCollection = self.collections[0]
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        makeConstraint()
        setSubviewClosure()
        PHPhotoLibrary.shared().register(self)
    }
    
    func setSubviewClosure() -> Void {
        
        assetCollectionPickerView.didPickCollectionClosure = { [weak self] in
            guard let self = self else { return }
            self.collectionSwitchButtonAction()
            guard $0 != self.pickedAssetCollection else {
                return
            }
            self.pickedAssetCollection = $0
        }
        
        switch style {
        case .multi(maxCount: _):
            imageAssetsView.didPickedPhotosCountChangeClosure = { [weak self] in
                guard let self = self else { return }
                self.multiSelectCompleteButton.setTitle("\($0)/\(self.style.maxCount)\("完成".localized)", for: .normal)
            }
        case .single(needCamera: _):
            imageAssetsView.didPickImageClosure = { [weak self] in
                guard let self = self else { return }
                self.didPickPhotoClosure?([$0])
            }
        case .singleForCrop(ratio: _):
            imageAssetsView.didPickImageClosure = { [weak self] in
                guard let self = self else { return }
                self.didPickPhotoClosure?([$0])
            }
        }
    }
    
    func makeConstraint() -> Void {
        
        topView.snp.makeConstraints {
            $0.top.equalTo(self.snp.top)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(44)
        }
        
        collectionSwitchButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(10)
            $0.width.equalTo(44)
        }
        
        switch style {
        case .multi(maxCount: _):
            multiSelectCompleteButton.snp.makeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.right.equalToSuperview().offset(-10)
            }
        default:
            break
        }
        
        imageAssetsView.snp.makeConstraints {
            $0.top.equalTo(topView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }
        assetCollectionPickerView.snp.makeConstraints {
            $0.edges.equalTo(imageAssetsView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionSwitchButton.layoutImageTitleHolizontallyCenterReverse(contentSpace: 0)
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return false
    }
    
    lazy var assetCollectionPickerView: YCAssetCollectionPickerView = {
        let temp = YCAssetCollectionPickerView.init(with: collections)
        temp.isHidden = true
        view.addSubview(temp)
        return temp
    }()
    
    lazy var imageAssetsView: YCImageAssetsView = {
        let temp = YCImageAssetsView.init(with: pickedAssetCollection, style: style)
        view.addSubview(temp)
        return temp
    }()
    
    lazy var topView: UIView = {
        let temp = UIView()
        temp.backgroundColor = UIColor.white
        view.addSubview(temp)
        return temp
    }()
    
    lazy var collectionSwitchButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setTitle(pickedAssetCollection?.collection.localizedTitle, for: .normal)
        temp.setImage(#imageLiteral(resourceName: "btn_icon_arrow_down"), for: .normal)
        temp.setImage(#imageLiteral(resourceName: "btn_icon_arrow_up"), for: .selected)
        temp.setTitleColor(.black, for: .normal)
        temp.addTarget(self, action: #selector(self.collectionSwitchButtonAction), for: .touchUpInside)
        topView.addSubview(temp)
        return temp
    }()
    
    lazy var closeButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setImage(#imageLiteral(resourceName: "btn_close"), for: .normal)
        temp.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        topView.addSubview(temp)
        return temp
    }()
    
    lazy var multiSelectCompleteButton: UIButton = {
        let temp = UIButton.init(type: .custom)
        temp.setTitle("0/\(style.maxCount)\("完成".localized)", for: .normal)
        temp.setTitleColor(UIColor.black, for: .normal)
        temp.addTarget(self, action: #selector(self.multiSelectCompleteAction), for: .touchUpInside)
        topView.addSubview(temp)
        return temp
    }()
    
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
                if let temp = self.pickedAssetCollection {
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
                        self.pickedAssetCollection = self.collections[0]
                    }
                }else {
                    self.pickedAssetCollection = self.collections[0]
                }
            }else {
                self.pickedAssetCollection = YCAssetCollection.init(collection: PHAssetCollection(), fetchResult: PHFetchResult<PHAsset>())
            }
        }
    }
}

private extension YCImagePickerHostViewController {
    
    @objc func collectionSwitchButtonAction() {
        
        collectionSwitchButton.isSelected = !collectionSwitchButton.isSelected
        let isHidden = !assetCollectionPickerView.isHidden
        assetCollectionPickerView.alpha = isHidden ? 1 : 0
        assetCollectionPickerView.isHidden = false
        UIView.animate(withDuration: 0.25, animations: { 
            self.assetCollectionPickerView.alpha = isHidden ? 0 : 1
        }) { (finished) in
            self.assetCollectionPickerView.isHidden = isHidden
            self.assetCollectionPickerView.alpha = 1
        }
        
    }
    
    @objc func closeAction() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func multiSelectCompleteAction() {
        
        let images = imageAssetsView.multiSelectPhotos
        if images.count == 0 {
            return
        }
        self.didPickPhotoClosure?(images)
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class YCImageAssetsView: UIView {
    
    let style: YCImagePickerStyle
    
    var itemSize = CGSize.zero
    var collection: YCAssetCollection? {
        
        didSet {
            self.imageCache = [:]
            self.collectionView.reloadData()
            self.didPickedPhotosCountChangeClosure?(0)
        }
    }
    
    var didPickImageClosure: ((UIImage) -> Void)?
    var didPickedPhotosCountChangeClosure: ((Int) -> Void)?
    var imageCache = [Int : UIImage]()
    var multiSelectPhotos: [UIImage] {
        
        var result = [UIImage]()
        switch style {
        case .multi(maxCount: _):
            if let selectIndexPaths = collectionView.indexPathsForSelectedItems {
                for indexPath in selectIndexPaths.sorted(by: { $0.row < $1.row }) {
                    if let image = imageCache[indexPath.item] {
                        result.append(image)
                    }
                }
            }
        default:
            break
        }
        return result
    }
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var previousPreheatRect = CGRect.zero
    
    init(with collection: YCAssetCollection?, style: YCImagePickerStyle) {
        self.style = style
        self.collection = collection
        super.init(frame: .zero)
        makeConstraint()
    }
    
    func makeConstraint() -> Void {
        
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        itemSize = CGSize.init(width: floor((UIScreen.main.bounds.width - 3)/3), height: floor((UIScreen.main.bounds.width - 3)/3))
        flowLayout.itemSize = itemSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let temp = UICollectionViewFlowLayout()
        temp.scrollDirection = .vertical
        temp.minimumInteritemSpacing = 1
        temp.minimumLineSpacing = 1
        return temp
    }()
    
    lazy var collectionView: UICollectionView = {
        let temp = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        switch style {
        case .multi(maxCount: _):
            temp.allowsMultipleSelection = true
        default:
            break
        }
        temp.backgroundColor = UIColor.white
        temp.register(YCImageAssetCollectionViewCell.self, forCellWithReuseIdentifier: "iden")
        temp.delegate = self
        temp.dataSource = self
        addSubview(temp)
        return temp
    }()
}

extension YCImageAssetsView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let temp = collection else { return style.needCamera ? 1 : 0 }
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
        }else {
            guard let temp = collection else { return cell }
            let index = needCamera ? indexPath.item + 1 : indexPath.item
            let asset = temp.fetchResult[index]
            imageManager.loadIconImage(asset: asset, targetSize: itemSize * UIScreen.main.scale, closure: { (image) in
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
            guard let temp = collection else { return }
            let asset = temp.fetchResult[indexPath.item]
            PHImageManager.default().loadHighQualityImage(asset: asset, completeClosure: {
                guard let image = $0 else {
                    collectionView.deselectItem(at: indexPath, animated: true)
                    return
                }
                self.imageCache[indexPath.item] = image
                if let indexPaths = collectionView.indexPathsForSelectedItems {
                    self.didPickedPhotosCountChangeClosure?(indexPaths.count)
                }else {
                    self.didPickedPhotosCountChangeClosure?(0)
                }
            }, requestActivityIndicatorVisible: false, target: viewController)
        case .single(needCamera: let needCamera):
            collectionView.deselectItem(at: indexPath, animated: true)
            if needCamera && indexPath.item == 0 {
                //打开摄像头
            }else {
                let index = needCamera ? indexPath.item + 1 : indexPath.item
                guard let temp = collection else { return }
                let asset = temp.fetchResult[index]
                PHImageManager.default().loadHighQualityImage(asset: asset, completeClosure: {
                    guard let image = $0 else { return }
                    self.didPickImageClosure?(image)
                }, requestActivityIndicatorVisible: false, target: viewController)
            }
        case .singleForCrop(ratio: let ratio):
            collectionView.deselectItem(at: indexPath, animated: true)
            let index = indexPath.item
            guard let temp = collection else { return }
            let asset = temp.fetchResult[index]
            PHImageManager.default().loadHighQualityImage(asset: asset, completeClosure: {
                guard let image = $0 else { return }
                let temp = YCImageCropViewController.init(image: image, cropMode: .fixableCrop(ratio), rotatable: true)
                temp.didCropClosure = { [weak temp] in
                    let image = $0.sub($1)
                    temp?.dismiss(animated: false, completion: {
                        self.didPickImageClosure?(image)
                    })
                }
                self.viewController?.present(temp, animated: false, completion: nil)
            }, requestActivityIndicatorVisible: false, target: viewController)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        switch style {
        case .multi(maxCount: _):
            self.imageCache.removeValue(forKey: indexPath.item)
            if let indexPaths = collectionView.indexPathsForSelectedItems {
                didPickedPhotosCountChangeClosure?(indexPaths.count)
            }else {
                didPickedPhotosCountChangeClosure?(0)
            }
        default:
            break
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard superview != nil else { return }
        guard let temp = collection else { return }
        
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
            .map { indexPath in temp.fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in temp.fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: itemSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: itemSize, contentMode: .aspectFill, options: nil)
        
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        selectedImageView.snp.makeConstraints {
            $0.right.bottom.equalToSuperview().offset(-5)
            $0.width.height.equalTo(18)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        
        didSet {
            selectedImageView.image = isSelected ? #imageLiteral(resourceName: "selection_icon") : #imageLiteral(resourceName: "unselected_icon")
        }
    }
    
    var selectable: Bool = false {
        
        didSet {
            selectedImageView.isHidden = !selectable
        }
    }
    
    lazy var imageView: UIImageView = {
        let temp = UIImageView()
        temp.clipsToBounds = true
        temp.contentMode = .scaleAspectFill
        contentView.addSubview(temp)
        return temp
    }()
    
    lazy var selectedImageView: UIImageView = {
        let temp = UIImageView()
        temp.isHidden = true
        temp.image = #imageLiteral(resourceName: "unselected_icon")
        contentView.addSubview(temp)
        return temp
    }()
}

class YCAssetCollectionPickerView: UIView {
    
    var collections: [YCAssetCollection] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var didPickCollectionClosure: ((YCAssetCollection) -> Void)?
    
    init(with collections: [YCAssetCollection]) {
        self.collections = collections
        super.init(frame: .zero)
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeConstraint() -> Void {
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    lazy var tableView: UITableView = {
        
        let temp = UITableView.init(frame: .zero, style: UITableView.Style.grouped)
        temp.backgroundColor = UIColor.clear
        temp.delegate = self
        temp.dataSource = self
        temp.rowHeight = 60
        temp.separatorInset = .zero
        temp.register(YCAssetCollectionTableCell.self, forCellReuseIdentifier: "iden")
        addSubview(temp)
        return temp
    }()
}

extension YCAssetCollectionPickerView: UITableViewDelegate, UITableViewDataSource {
    
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
        cell.nameLabel.text = collections[indexPath.row].collection.localizedTitle
        cell.countLabel.text = "\(collections[indexPath.row].fetchResult.count)"
        if let asset = collections[indexPath.row].fetchResult.firstObject {
            PHImageManager.default().loadIconImage(asset: asset, targetSize: CGSize.init(width: 60, height: 60)*UIScreen.main.scale, closure: { (image) in
                cell.reprImageView.image = image
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        didPickCollectionClosure?(collections[indexPath.row])
    }
}

class YCAssetCollectionTableCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        makeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeConstraint() -> Void {
        
        reprImageView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(12)
            $0.width.equalTo(reprImageView.snp.height)
        }
        nameLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(reprImageView.snp.right).offset(8)
        }
        countLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().offset(-12)
            $0.left.greaterThanOrEqualTo(nameLabel.snp.right)
            $0.width.equalTo(nameLabel.snp.width).dividedBy(2)
        }
    }
    
    lazy var reprImageView: UIImageView = {
        let temp = UIImageView()
        temp.clipsToBounds = true
        temp.contentMode = .scaleAspectFill
        contentView.addSubview(temp)
        return temp
    }()
    
    lazy var nameLabel: UILabel = {
        let temp = UILabel()
        temp.textAlignment = .left
        temp.textColor = .black
        temp.font = Config.regularFont?(16)
        contentView.addSubview(temp)
        return temp
    }()
    
    lazy var countLabel: UILabel = {
        let temp = UILabel()
        temp.textAlignment = .right
        temp.textColor = .lightGray
        temp.font = Config.regularFont?(11)
        contentView.addSubview(temp)
        return temp
    }()
}

extension UIView {
    
    var viewController: UIViewController? {
        
        var temp = next
        while temp != nil {
            if let vc = temp as? UIViewController {
                return vc
            }
            temp = temp?.next
        }
        return nil
    }
}
