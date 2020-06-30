//
//  ViewController.swift
//  CircularSlider
//
//  Created by Thomas on 2018-05-26.
//  Copyright © 2018 Thomas Lock. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, CircularSliderDelegate, UICollectionViewDataSource {
    
    @IBOutlet var libraryCollectionView: UICollectionView!
    @IBOutlet var circularSlider: CircularSlider!
    @IBOutlet var backgroundImage: UIImageView!
    
    fileprivate var totalImages: Int = 10
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        circularSlider.delegate = self
        
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({[unowned self] status in
                if status == .authorized{
                    self.loadPhotoLibary()
                } else {
                    //TODO: Add Alert
                }
            })
        }
        else {
            self.loadPhotoLibary()
        }
    }
    
    func loadPhotoLibary() {
        if self.fetchResult == nil {
            DispatchQueue.main.async { [unowned self] in
                self.libraryCollectionView.dataSource = self
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
                self.libraryCollectionView.reloadData()
            }
        }
    }
}

//MARK: - CircularSliderDelegate Methods
extension ViewController {

    func tapped(angle: CGFloat) {
        let n = Int(arc4random_uniform(UInt32(360)))
        self.circularSlider.sliderValue = Double(CGFloat(n))
        
        let asset = fetchResult.object(at: Int(Double(n) / 360.0 * Double(totalImages)))
        imageManager.requestImage(for: asset, targetSize: self.backgroundImage.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            self.backgroundImage.image = image
        })
    }
    
    func panned(angle: CGFloat, pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .ended:
            let asset = fetchResult.object(at: Int(Double(angle) / 360.0 * Double(totalImages)))
            imageManager.requestImage(for: asset, targetSize: self.backgroundImage.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                self.backgroundImage.image = image
            })
        default:
            break;
        }
    }
}

//MARK: - Collection DataSource Methods
extension ViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalImages = (fetchResult.count > 10) ? 10 : fetchResult.count
        return totalImages
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LibraryImageCollectionViewCell
        
        let asset = fetchResult.object(at: indexPath.item)

        imageManager.requestImage(for: asset, targetSize: cell.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            cell.layer.cornerRadius = 4.0
            cell.clipsToBounds = true
            cell.image.image = image
        })
        return cell
    }
}
