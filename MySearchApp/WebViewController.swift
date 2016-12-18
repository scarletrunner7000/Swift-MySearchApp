//
//  WebViewController.swift
//  MySearchApp
//
//  Created by 稲垣悠一 on 2016/08/16.
//  Copyright © 2016年 稲垣悠一. All rights reserved.
//

import Foundation
import UIKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    var itemData = ItemData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let itemUrl = itemData.itemUrl {
            if let url = NSURL(string: itemUrl){
                let request = NSURLRequest(URL: url)
                webView.loadRequest(request)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}




