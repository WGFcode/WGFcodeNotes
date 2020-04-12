//
//  WGMainVC.swift
//  WGFcodeNotes
//
//  Created by wubaicai on 2020/3/28.
//  Copyright © 2020 WG. All rights reserved.
//

import Foundation
import UIKit

public final class WGTestEntity : NSObject {
    static let instance = WGTestEntity()
    override init() {
        super.init()
    }
}

public class WGMainVC : UIViewController {
    private var thread1: Thread?=nil
    private var isSuccess2 = true
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        
        NSLog("开始了")
        DispatchQueue.global().asyncAfter(deadline: DispatchTimeInterval.seconds(3)) {
            NSLog("11111--\(Thread.current)")
        }
        NSLog("完成了")
      
        
        
        NSLog("👌开始了")
        DispatchQueue.global().asyncAfter(wallDeadline: DispatchWallTime.init(timespec: <#T##timespec#>)) {
            NSLog("👌11111--\(Thread.current)")
        }
        NSLog("👌完成了")
        
    }
    

}



