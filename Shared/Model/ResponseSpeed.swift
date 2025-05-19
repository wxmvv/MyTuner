//
//  ResponseSpeed.swift
//  MyTuner
//
//  Created by wxm on 4/2/25.
//

import AudioKit
import SwiftUI


enum ResponseSpeed:String {
//    case shortest
//    case veryShort
    case short="short"
    case medium="medium"
    case long="long"
//    case veryLong
//    case huge
//    case longest
    
    /// bufferLength
    /// 越小 分析的音频越短，则响应更快，但同时也可能影响准确度
    /// 反之 越大则越准确，但响应会变慢
    /// 如果 bufferLength 太小（如 32 或 64），在低端设备上可能导致音频处理跟不上，出现爆音或崩溃 则只从short开始可以设置

    
    var name: LocalizedStringKey {
        switch self {
//        case .shortest:
//            return "Fastest"
//        case .veryShort:
//            return "Very Fast"
        case .short:
            return "Fast"
        case .medium:
            return "Normal"
        case .long:
            return "Slow"
//        case .veryLong:
//            return "Very Slow"
//        case .huge:
//            return "Very Very Slow"
//        case .longest:
//            return "Slowest"
        }
    }
    
    var bufferLength: Settings.BufferLength {
        switch self {
//        case .shortest:
//            return .shortest
//        case .veryShort:
//            return .veryShort
        case .short:
            return .short
        case .medium:
            return .medium
        case .long:
            return .long
//        case .veryLong:
//            return .veryLong
//        case .huge:
//            return .huge
//        case .longest:
//            return .longest
        }
    }
    
}
