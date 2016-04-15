//
//  ViewController.swift
//  LXYNetPlayer
//
//  Created by 李 欣耘 on 16/4/15.
//  Copyright © 2016年 lixinyun. All rights reserved.
//

import UIKit

class ViewController: UIViewController,LXYNetPlayerDelegate {

    private var player : LXYNetPlayerSwift?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player = LXYNetPlayerSwift.shareInstance()
       // player?.playWith(<#T##paths: NSArray?##NSArray?#>, taskid: <#T##NSString?#>)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    internal func playDone() {
    
    }
    internal func playStart(item: PlayItem) {
        
    }
    internal func playFail() {
        
    }
    internal func bufferLoading() {
        
    }
    internal func loadEnd() {
        
    }
    internal func playChange(item: PlayItem) {
        
    }


}

