//
//  AppIcon.swift
//  MyTuner
//
//  Created by wxm on 5/17/25.
//

import SwiftUI
import UIKit
import Foundation


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

