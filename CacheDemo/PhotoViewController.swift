//
//  PhotoViewController.swift
//  CacheDemo
//
//  Created by Raunak Poddar on 14/10/19.
//  Copyright © 2019 Raunak. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: RPImageView!
    var photoURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = photoURL {
            self.imageView.rp_setImage(fromURL: url)
        }
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
