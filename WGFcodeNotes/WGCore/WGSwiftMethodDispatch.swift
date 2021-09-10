//
//  WGSwiftMethodDispatch.swift
//  WGFcodeNotes
//
//  Created by 白菜 on 2021/9/10.
//  Copyright © 2021 WG. All rights reserved.
//

import Foundation

//MARK: 消息派发
public class WGMethodDispatchStatic {
    public init() {}
    
    func printMethodName() -> String {
        let name = getMethodName()
        return name
    }
    
    @objc dynamic func getMethodName() -> String {
        let name = "swift static dispatch method"
        return name
    }
}
