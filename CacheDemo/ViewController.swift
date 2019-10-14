//
//  ViewController.swift
//  CacheDemo
//
//  Created by Raunak Poddar on 13/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import UIKit

let CellReuseIdentifier = "Cell"

class ViewController: UICollectionViewController {
    
    let path = "http://pastebin.com/raw/wgkJgazE"
    let downloadManager = DownloadManager()
    var photos = Photos()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.register(CollectionViewCell.self, forCellWithReuseIdentifier: CellReuseIdentifier)
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        self.collectionView!.collectionViewLayout = layout
        
        self.initializePhotos()
    }
    
    func initializePhotos() {
        if let url = URL.init(string: path) {
            let downloadRequest = downloadManager.downloadItem(atURL: url) { [weak self] (data: Data?) in
                guard let self = self else { return }
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    self.photos = try! decoder.decode(Photos.self, from: data) as Photos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let CellIdentifier = "Cell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! CollectionViewCell
        let photo = self.photos[(indexPath as NSIndexPath).row]

        let url = URL(string:photo.urls!.thumb!)!
        cell.imageView.rp_setImage(fromURL: url)
        return cell
    }
    
    
}

