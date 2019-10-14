//
//  UIImageView+Cache.swift
//  CacheDemo
//
//  Created by Raunak Poddar on 14/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import UIKit

class RPImageView: UIImageView {
    private static var downloadManager = DownloadManager()
    private var rp_downloadRequest : ItemDownloadRequest?
    
    func rp_setImage(fromURL url: URL) {
        rp_downloadRequest = RPImageView.downloadManager.downloadItem(atURL: url, completionHandler: { [weak self] (data: Data?) in
            guard let self = self else {
                return
            }
            if let data = data {
                let img = UIImage.init(data: data)
                DispatchQueue.main.async {
                    self.image = img
                }
            }
        })
    }
    
    func rp_cancelSet() {
        rp_downloadRequest?.cancel()
    }
}
