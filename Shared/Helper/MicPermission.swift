//
//  MicPermission.swift
//  MyTuner
//
//  Created by wxm on 5/18/25.
//

import SwiftUI
import AVFoundation

enum MicPermissionStatus: String {
    case undetermined = "undetermined"
    case granted = "granted"
    case denied = "denied"
}

func getMicPermissionStatus() -> MicPermissionStatus {
    if #available(iOS 17.0, *) {
        let status = AVAudioApplication.shared.recordPermission
        switch status {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .undetermined
            @unknown default:
                return .undetermined
        }
    }else {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .undetermined
            @unknown default:
                return .undetermined
        }
    }
}


struct MicPermissionButton : View {
    @Binding var micPermissionStatus:MicPermissionStatus
    
    var body: some View {
        switch micPermissionStatus {
            case .granted:
                Text("Microphone permission granted~ 🎉")
                    .foregroundStyle(LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing))
            case .undetermined:
                Button("Request microphone permission.."){
                    if #available(iOS 17.0, *){
                        print("iOS 17")
                        let status = AVAudioApplication.shared.recordPermission
                        switch status {
                            case .undetermined:
                                AVAudioApplication.requestRecordPermission { granted in
                                    print("requestRecordPermission granted: \(String(granted))")
                                    DispatchQueue.main.async {
                                        if granted {
                                            print("权限已授予")
                                            micPermissionStatus = .granted
                                        } else {
                                            print("权限被拒绝 undetermined")
                                            micPermissionStatus = .denied
                                        }
                                    }
                                }
                            case .granted:
                                print("权限已授予 granted")
                                micPermissionStatus = .granted
                            case .denied:
                                print("权限已被拒绝 denied")
                                micPermissionStatus = .denied
                            @unknown default:
                                print("未知状态")
                                micPermissionStatus = .undetermined
                        }
                        
                    }else {
                        print("iOS 16")
                        let status = AVAudioSession.sharedInstance().recordPermission
                        switch status {
                            case .undetermined:
                                AVAudioSession.sharedInstance().requestRecordPermission{ granted in
                                    if granted {
                                        micPermissionStatus = .granted
                                    } else {
                                        print("权限被拒绝 undetermined")
                                        micPermissionStatus = .denied
                                    }
                                }
                            case .granted:
                                print("权限已授予 granted")
                                micPermissionStatus = .granted
                            case .denied:
                                print("Microphone permission Denied，Please grant permissions in the settings interface.")
                                micPermissionStatus = .denied
                            @unknown default:
                                print("未知状态")
                                micPermissionStatus = .undetermined
                        }
                    }
                }.buttonStyle(.automatic)
            case .denied:
                Button("Microphone permission Denied，Please grant permissions in the settings interface."){
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }.buttonStyle(.automatic)
        }
    }
    
}
