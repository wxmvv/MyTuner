//
//  SettingsView.swift
//  MyTuner
//
//  Created by wxm on 3/27/25.
//

import SwiftUI
import UIKit
import AVFoundation
import AudioKit
import UIKit


struct ListSettingsViewSheet : View {
    var conductor: TunerConductor
    var instrumentConductor: InstrumentConductor
    @Binding var showSettingsSheet: Bool
    
    var body: some View {
        NavigationStack{
            VStack(spacing:0){
                
                ListSettingsView(conductor: conductor,instrumentConductor: instrumentConductor)
                
#if targetEnvironment(macCatalyst)
                Button {
                    showSettingsSheet = false
                } label: {
                    HStack{
                        Text("Close")
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.primary.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .padding(10)
                }
#endif
            }
        }
    }
}


struct ListSettingsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentation: Binding<PresentationMode>
    @State private var isPitchStandardPickerShow: Bool = false
    @State private var micPermissionStatus:MicPermissionStatus = .undetermined
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = 0.2
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    @AppStorage("responseSpeed") private var responseSpeed:ResponseSpeed = .medium
    @AppStorage("velocity") private var velocity = 100
    @AppStorage("instrumentIndex") private var instrumentIndex = 0
    
    @State private var velocityVal = 100.0
    @State private var velocityRange = 60.0...120.0
    
    var conductor: TunerConductor? = nil
    var instrumentConductor: InstrumentConductor? = nil
    var isSheet: Bool = false
    
    var body: some View {
        NavigationStack{
            List {
                Group{
                    // Permissions
                    Section("Permissions"){
                        MicPermissionButton(micPermissionStatus: $micPermissionStatus)
                    }
                    
                    // Instrument
                    Section("Tuning Mode") {
                        
                        // Tuning Mode
                        Menu {
                            ForEach(tuningModes, id: \.self) { mode in
                                Button(String(mode.name)) {
                                    tuningMode = mode
                                    if conductor != nil {
                                        conductor!.tuningMode = mode
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Amplitude Limit")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(tuningMode.name))
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
                        
                        
                        // Instrument
                        if tuningMode == .instrument {
                            InstrumentsMenuItem(conductor: conductor)
                        }
                        
                        // preferredName
                        ModifierPreferenceMenuItem()
                        
                    }
                    
                    // Tuner
                    Section("Tuner") {
                        
                        // In-tune Range
                        InTuneRangeMenuItem()
                        
                        // responseSpeed
                        ResponseSpeedMenuItem()
                        
                        // Amplitude Limit
                        AmplitudeLimitMenuItem(conductor: conductor)
                        
                        // Pitch Standard
                        Button{
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPitchStandardPickerShow.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Pitch Standard")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(pitchStandard)+"Hz")
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
                        
                        if isPitchStandardPickerShow{
                            Picker("Pitch Standard",selection: $pitchStandard) {
                                ForEach(pitchStandardValues, id: \.self) { val in
                                    Text(val == 440 ? "440Hz - Standard" : String(val))
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .animation(.easeInOut(duration: 0.3), value: pitchStandard)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: -20)),
                                removal: .opacity.combined(with: .offset(y: -20))
                            ))
                            
                            Button {
                                pitchStandard = 440
                            } label: {
                                HStack{
                                    Spacer()
                                    Text("Reset to A:440Hz")
                                }
                                
                            }
                            
                        }
                    }
                    
                    // Tone
                    Section("Tone") {
                        Menu {
                            ForEach(0...availableInstruments.count-1,id:\.self) { index in
                                Button(availableInstruments[index].displayName) {
                                    instrumentIndex = index
                                    instrumentConductor?.instrumentIndex = index
                                }
                            }
                        } label: {
                            HStack {
                                Text("Sound")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(availableInstruments[instrumentIndex].displayName) )
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                        }
//                        
                        HStack {
                            Text("velocity: \(velocityVal,specifier:"%.0f")")
                            Spacer()
                            Slider(value: $velocityVal,in: velocityRange ,step:10){
                                Text("velocity:\(velocityVal,specifier:"%.0f")")
                            } onEditingChanged: { isEdited in
                                velocity = Int(velocityVal)
                                instrumentConductor?.velocity = MIDIVelocity(velocityVal)
                            }
                        }

                    }
                    
#if !targetEnvironment(macCatalyst)
                    // Appicon
                    Section("App Icon") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack{
                                ForEach(appIcons, id: \.self) { icon in
                                    Button(action: {
                                        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
                                            if error != nil {
                                                print("更换应用图标失败\n\(String(describing: error?.localizedDescription))")
                                            }
                                        }
                                    }) {
                                        Image(icon.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(10)
                                            .frame(width: 80, height: 80)
                                            .padding(8)
                                    }
                                }
                            }
                        }
                    }
#endif
                    
                    // About
                    Section("About") {
                        
                        // Version
                        HStack{
                            Text("Version")
                            Spacer()
                            Text(AppVersion())
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        
                        // Contact
                        Button(action: {
                            if let url = URL(string: "mailto:w05172075@icloud.com") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Text("Contact")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                            
                        }
                        
                        // Leave a Review
                        Button(action: {
//                            TODO
                            if let url = URL(string: "https://apps.apple.com/app/id0000000000") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Text("Leave a Review")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.primary.opacity(0.7))
                            }
                            
                        }
                    }
                    
                }
                // style
                .listRowSeparatorTint(Color.primary.opacity(0.2)) // 分割线
                .listRowBackground(Color.primary.opacity(0.1)) // row背景
                // copy right
                Text("© 2025 wxmvv.cc. All rights reserved.")
                    .listRowBackground(Color.white.opacity(0))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,100)
                
            }
            .myNavBarTitle("Settings",show: isSheet)
            // style background
            .scrollContentBackground(.hidden)  // 整体背景
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentation.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .onAppear(){
                instrumentIndex = max(0, min(instrumentIndex, availableInstruments.count - 1))
                micPermissionStatus = getMicPermissionStatus()
                velocityVal = Double(velocity)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct AmplitudeLimitMenuItem: View {
    @AppStorage("amplitudeLimit") private var amplitudeLimit = 0.075
    var conductor: TunerConductor? = nil
    
    var body: some View{
        Menu {
            ForEach(amplitudeLimitValues, id: \.self) { val in
                Button(String(val)) {
                    amplitudeLimit = val
                    if conductor != nil {
                        conductor!.amplitudeLimit = Float(val)
                    }
                }
            }
        } label: {
            HStack {
                Text("Amplitude Limit")
                    .foregroundColor(.primary)
                Spacer()
                Text(String(amplitudeLimit))
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

struct SmoothingFactorMenuItem: View {
    @AppStorage("smoothingFactor") private var smoothingFactor = 0.2
    var conductor: TunerConductor? = nil
    
    var body: some View{
        Menu {
            ForEach(smoothingFactorValues, id: \.self) { val in
                Button(String(val)) {
                    smoothingFactor = val
                    if conductor != nil {
                        conductor!.amplitudeLimit = Float(val)
                    }
                }
            }
        } label: {
            HStack {
                Text("Amplitude Limit")
                    .foregroundColor(.primary)
                Spacer()
                Text(String(smoothingFactor))
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

struct ResponseSpeedMenuItem: View {
    @AppStorage("responseSpeed") private var responseSpeed:ResponseSpeed = .medium
    
    var body: some View{
        Menu {
            ForEach(responseSpeedValues, id: \.self) { speed in
                Button(speed.name) {
                    responseSpeed = speed
                    Settings.bufferLength = speed.bufferLength
                }
            }
        } label: {
            HStack {
                Text("Response Speed")
                    .foregroundColor(.primary)
                Spacer()
                Text(responseSpeed.name)
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

struct InTuneRangeMenuItem: View {
    @AppStorage("inTuneRange") private var inTuneRange = 2
    
    var body: some View{
        Menu {
            ForEach(inTuneRangeValues, id: \.self) { val in
                Button(String(val) + " cents") {
                    inTuneRange = val
                }
            }
        } label: {
            HStack {
                Text("In-tune Range")
                    .foregroundColor(.primary)
                Spacer()
                Text(String(inTuneRange) + " cents")
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

struct ModifierPreferenceMenuItem: View {
    @AppStorage("preferredName") private var preferredName:ModifierPreference = .preferSharps
    
    var body: some View {
        Menu {
            ForEach(ModifierPreference.allCases, id: \.self) { val in
                Button(String(val.name)) {
                    preferredName = val
                }
            }
        } label: {
            HStack {
                Text("Preferred Name")
                    .foregroundColor(.primary)
                Spacer()
                Text(String(preferredName.name) )
                    .foregroundColor(.primary.opacity(0.7))
            }
        }
    }
}

struct InstrumentsMenuItem: View {
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("instrument") private var instrument:Instrument = .Acoustic
    var conductor: TunerConductor? = nil
    
    var body: some View {
        Menu {
            ForEach(instruments, id: \.self) { ins in
                Button(ins.name) {
                    instrument = ins
                    if conductor != nil {
                        conductor!.instrument = ins
                    }
                }
            }
        } label: {
            VStack (spacing: 20) {
                HStack {
                    Text("Instrument")
                        .foregroundColor(.primary)
                    Spacer()
                    VStack{
                        Text(instrument.name)
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
                HStack{
                    Spacer()
                    ForEach(instrument.notes(referenceFrequency: Float(pitchStandard))) { note in
                        HStack(spacing: 0){
                            Text(note.noteNameString)
                                .foregroundColor(.primary.opacity(0.7))
                            Text("\(note.octave)")
                                .foregroundColor(.primary.opacity(0.7))
                                .font(.footnote)
                        }
                    }
                }
            }
        }
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1200)){
    ListSettingsView()
}

