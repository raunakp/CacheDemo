//
//  ViewController.swift
//  CacheDemo
//
//  Created by Raunak Poddar on 13/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import UIKit

extension Array {
    init(repeating: [Element], count: Int) {
        self.init([[Element]](repeating: repeating, count: count).flatMap{$0})
    }
    
    func repeated(count: Int) -> [Element] {
        return [Element](repeating: self, count: count)
    }
}


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
            let _ = downloadManager.downloadItem(atURL: url) { [weak self] (data: Data?) in
                guard let self = self else { return }
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let photos = try! decoder.decode(Photos.self, from: data) as Photos
                    self.photos = photos.repeated(count: 10)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UICollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell),
            let pvc = segue.destination as? PhotoViewController {
            let photo = self.photos[(indexPath as NSIndexPath).row]
            let url = URL(string:photo.urls!.full!)!
            pvc.photoURL = url
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = self.photos[(indexPath as NSIndexPath).row]
        let url = URL(string:photo.urls!.full!)!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
        controller.photoURL = url
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let CellIdentifier = "Cell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! CollectionViewCell
        let photo = self.photos[(indexPath as NSIndexPath).row]
        
        let url = URL(string:photo.urls!.thumb!)!
        cell.imageView.setPlaceholderImage(named: "loading")
        cell.imageView.rp_setImage(fromURL: url)
        return cell
    }
    
    
}

