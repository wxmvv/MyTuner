//
//  SettingsView.swift
//  MyTuner
//
//  Created by wxm on 3/26/25.
//

import SwiftUI
import AVFoundation
import AudioKit


struct CustomSettingsViewSheet : View {
    var conductor: TunerConductor
    var instrumentConductor: InstrumentConductor
    @Binding var showSettingsSheet: Bool
    
    var body: some View {
        NavigationStack{
            VStack(spacing:0){
                CustomSettingsView(conductor: conductor,instrumentConductor: instrumentConductor)
                
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


struct CustomSettingsView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentation: Binding<PresentationMode>
    @State private var isPitchStandardPickerShow: Bool = false
    @State private var haveMicPermission = false
    @State private var micPermissionStatus:MicPermissionStatus = .undetermined
    
    @AppStorage("smoothingFactor") private var smoothingFactor: Double = 0.5
    @AppStorage("inTuneRange") private var inTuneRange: Int = 2
    @AppStorage("pitchStandard") private var pitchStandard = 440
    @AppStorage("amplitudeLimit") private var amplitudeLimit: Double = 0.2
    @AppStorage("preferredName") private var preferredName: ModifierPreference = .preferSharps
    @AppStorage("tuningMode") private var tuningMode: TuningMode = .chromatic
    @AppStorage("instrument") private var instrument: Instrument = .Acoustic
    @AppStorage("responseSpeed") private var responseSpeed:ResponseSpeed = .medium
    
    @AppStorage("velocity") var velocity = 100
    @AppStorage("instrumentIndex") var instrumentIndex = 0
    @State private var velocityVal = 100.0
    @State private var velocityRange = 60.0...120.0
    
    var conductor: TunerConductor? = nil
    var instrumentConductor: InstrumentConductor? = nil
    var isSheet: Bool = false
    
    var body: some View {
        NavigationStack{
            CustomScrollView{
                // Permissions
                CustomSettingsSection(title: "Permissions") {
                    if haveMicPermission {
                        HStack {
                            Text("Microphone permission granted~ 🎉")
                                .foregroundStyle(LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing))
                            Spacer()
                        }
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(15)
                    } else {
                        HStack{
                            Button("Request microphone permission.."){
                                AVAudioSession.sharedInstance().requestRecordPermission{ granted in
                                    if granted {
                                        haveMicPermission = true
                                    }
                                }
                            }
                            Spacer()
                        }
                        .buttonStyle(.automatic)
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(15)
                    }
                }
                
                // Instrument
                CustomSettingsSection(title: "Tuning Mode") {
                    
                    Menu {
                        ForEach(tuningModes, id: \.self) { val in
                            Button(String(val.name)) {
                                tuningMode = val
                            }
                        }
                    } label: {
                        HStack {
                            Text("Mode")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(String(tuningMode.name) )
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        .padding()
                        .background(Color.primary.opacity(0.15))
                    }
                    
                    if tuningMode == .instrument {
                        Menu {
                            ForEach(instruments, id: \.self) { ins in
                                Button(ins.name) {
                                    instrument = ins
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
                                        Text(note.noteNameString)
                                            .foregroundColor(.primary.opacity(0.7))
                                    }
                                }
                            }
                            .padding()
                            .background(Color.primary.opacity(0.15))
                        }
                    }
                    
                    // preferredName
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                    }
                }
                
                // Tuner
                CustomSettingsSection(title: "Tuner") {
                    
                    // In-tune Range
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                    
                    // responseSpeed
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                    
                    // Amptude Limit
                    Menu {
                        ForEach(amplitudeLimitValues, id: \.self) { val in
                            Button(String(val)) {
                                amplitudeLimit = val
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                    
                    // Pitch Standard
                    Button{
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPitchStandardPickerShow.toggle()
                        }
                    }label: {
                        HStack {
                            Text("Pitch Standard")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(String(pitchStandard)+"Hz")
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                    
                    if isPitchStandardPickerShow{
                        VStack {
                            HStack {
                                Button("Reset to A:440Hz"){
                                    pitchStandard = 440
                                }.padding()
                                Spacer()
                            }
                            Picker("Pitch Standard",selection: $pitchStandard) {
                                ForEach(pitchStandardValues, id: \.self) { val in
                                    Text(val == 440 ? "440Hz - Standard" : String(val))
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                        }
                        .background(Color.primary.opacity(0.1))
                        .animation(.easeInOut(duration: 0.3), value: pitchStandard)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -20)),
                            removal: .opacity.combined(with: .offset(y: -20))
                        ))
                    }
                }
                
                // Tone
                CustomSettingsSection(title: "Tone") {
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
                    .padding()
                    .background(Color.primary.opacity(0.15))
                    .cornerRadius(0)
                    
                    
                    HStack {
                        Text("velocity: \(velocityVal,specifier:"%.0f")")
                        Spacer()
                        Slider(value: $velocityVal,in: velocityRange ,step:10){
                            Text("velocity: \(velocityVal,specifier:"%.0f")")
                        } onEditingChanged: { isEdited in
                            velocity = Int(velocityVal)
                            instrumentConductor?.velocity = MIDIVelocity(velocityVal)
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.15))
                    .cornerRadius(0)
                }
                
                
#if !targetEnvironment(macCatalyst)
                // Appicon
                CustomSettingsSection(title: "App Icon") {
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
                                        .frame(width: 80, height: 80)
                                        .padding(8)
                                }
                            }
                        }
                    }
                }
#endif
                
                // About
                CustomSettingsSection(title: "About") {
                    HStack{
                        Text("Version")
                        Spacer()
                        Text(AppVersion())
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .padding()
                    .background(Color.primary.opacity(0.15))
                    .cornerRadius(0)
                    
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/app/id6746087511") {
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
                        .padding()
                        .background(Color.primary.opacity(0.15))
                        .cornerRadius(0)
                    }
                }
                
                Text("© 2025 wxmvv.cc. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,100)
                
            }
            .myNavBarTitle("Settings",show: isSheet)
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
                AVAudioSession.sharedInstance().requestRecordPermission{ granted in
                    if granted {
                        haveMicPermission = true
                    }
                }
                velocityVal = Double(velocity)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}


// 自定义ScrollView
struct CustomScrollView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        ZStack {
            Color.black.opacity(0).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 30) {
                    content
                }
                .padding()
                .padding(.bottom,50)
            }
        }
    }
}

// 自定义Section
struct CustomSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading, 5)
            
            VStack(spacing: 1) {
                content
            }
            .cornerRadius(15)
            //   .overlay(
            //       RoundedRectangle(cornerRadius: 15)
            //        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            //    )
        }
    }
}



@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    CustomSettingsView()
}
