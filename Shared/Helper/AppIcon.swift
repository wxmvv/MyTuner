//
//  AppIcon.swift
//  MyTuner
//
//  Created by wxm on 5/17/25.
//

import SwiftUI
import UIKit
import Foundation

///// 获取当前所有的 AppIcon 集
//if let iconsDict = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String:Any] {
//    if let alternateIcons = iconsDict["CFBundleAlternateIcons"] as? [String:Any] {
//        debugPrint(alternateIcons.keys)
//        alternateIcons.keys.forEach { item in
//            debugPrint(item)
//        }
//    }
//}
//
///// 更换应用图标
//UIApplication.shared.setAlternateIconName(iconName) { error in
//    if error != nil {
//        print("更换应用图标失败\n\(String(describing: error?.localizedDescription))")
//    }
//}
//
///// 恢复默认应用图标
//UIApplication.shared.setAlternateIconName(nil, completionHandler: nil)

enum AppIcon : String {
    case icon1 = "AppIcon 1"
    case icon2 = "AppIcon 2"
    
    var imageName: String {
        switch self {
            case .icon1:
                return "AppIcon 1"
            case .icon2:
                return "AppIcon 2"
        }
    }
    
    var iconName: String {
        switch self {
            case .icon1:
                return "AppIcon-light"
            case .icon2:
                return "AppIcon-dark"
        }
    }
}

