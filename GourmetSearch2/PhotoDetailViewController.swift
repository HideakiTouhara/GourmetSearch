//
//  PhotoDetailViewController.swift
//  GourmetSearch2
//
//  Created by HideakiTouhara on 2017/09/14.
//  Copyright © 2017年 HideakiTouhara. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photo: UIImageView!
    
    var image: UIImage = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photo.alpha = 0
        photo.image = image

    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentInset.top = (scrollView.bounds.size.height - photo.bounds.size.height) / 2.0
        scrollView.contentInset.bottom = (scrollView.bounds.size.height - photo.bounds.size.height) / 2.0
        
        scrollView.setZoomScale(1, animated: true)
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.1, animations:  {
            self.photo.alpha = 1
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photo
    }

}
