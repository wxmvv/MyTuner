//
//  AppVersion.swift
//  MyTuner
//
//  Created by wxm on 3/27/25.
//

import Foundation

public func AppVersion() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(appVersion) (\(buildNumber))"
}
