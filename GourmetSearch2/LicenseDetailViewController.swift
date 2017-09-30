//
//  LicenseDetailViewController.swift
//  GourmetSearch2
//
//  Created by HideakiTouhara on 2017/09/15.
//  Copyright © 2017年 HideakiTouhara. All rights reserved.
//

import UIKit

class LicenseDetailViewController: UIViewController {
    @IBOutlet weak var text: UILabel!
    @IBOutlet weak var textHeight: NSLayoutConstraint!
    
    var name = ""
    var license = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    
        text.text = license
        title = name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        let frame = CGSize(width: text.frame.size.height, height: CGFloat.greatestFiniteMagnitude)
        textHeight.constant = text.sizeThatFits(frame).height
        view.layoutIfNeeded()
    }


}
