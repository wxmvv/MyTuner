//
//  Tuner.swift
//  MyTuner
//
//  Created by wxm on 3/24/25.
//

import AudioKit
import AudioKitUI
import SwiftUI


struct CookbookTunerView: View {
    
    @StateObject var conductor = TunerConductor()
    @AppStorage("pitchStandard") private var pitchStandard = 440
    
    @State private var refFreqInput: String = "440"  // 用于 TextField 输入
    @State private var ampLimitInput: String = "0.1"
    
    var body: some View {
        VStack {
            HStack {
                Text("Frequency")
                Spacer()
                Text("\(conductor.data.pitch, specifier: "%0.2f")")
            }.padding()
            
            HStack {
                Text("Amplitude")
                Spacer()
                Text("\(conductor.data.amplitude, specifier: "%0.2f")")
            }.padding()
            
            HStack {
                Text("Note Name")
                Spacer()
                Text("\(conductor.data.noteNameWithSharps) / \(conductor.data.noteNameWithFlats)")
            }.padding()
            HStack {
                Text("Reference A4 (Hz)")
                Spacer()
                TextField("Enter Hz", text: $refFreqInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 100)
                    .onChange(of: refFreqInput) { newValue in
                        if let value = Float(newValue), value > 0 {
                            conductor.pitchStandard = value
                        }
                    }
            }.padding()
            HStack {
                Text("Reference AmpLimit (Mic Sensitivity)")
                Spacer()
                TextField("Enter Hz", text: $ampLimitInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numbersAndPunctuation)
                    .frame(maxWidth: 100)
                    .onChange(of: ampLimitInput) { newValue in
                        if let value = Float(newValue), value > 0 {
                            conductor.amplitudeLimit = value
                        }
                    }
            }.padding()
            HStack{
                Text("Distance (Hz)")
                Spacer()
                Text("Float: \(conductor.data.frequencyDistance, specifier: "%0.2f")")
                Text("Int: \(conductor.data.frequencyDistance, specifier: "%0.0f")")
                Text(String(Int(round(conductor.data.frequencyDistance))))
            }.padding()
            
            InputDevicePicker(device: conductor.initialDevice)
            
            NodeRollingView(conductor.tappableNodeA).clipped()
            
            NodeOutputView(conductor.tappableNodeB).clipped()
            
            NodeFFTView(conductor.tappableNodeC).clipped()
        }
        .navigationTitle("Dev Tuner View")
        .onAppear {
            conductor.pitchStandard = Float(pitchStandard)
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}

struct InputDevicePicker: View {
    @State var device: Device
    
    var body: some View {
        Picker("Input: \(device.deviceID)", selection: $device) {
            ForEach(getDevices(), id: \.self) {
                Text($0.deviceID)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: device, perform: setInputDevice)
    }
    
    func getDevices() -> [Device] {
        AudioEngine.inputDevices.compactMap { $0 }
    }
    
    func setInputDevice(to device: Device) {
        do {
            try AudioEngine.setInputDevice(device)
        } catch let err {
            print(err)
        }
    }
}


@available(iOS 17, *)
#Preview(traits: .fixedLayout(width: 500, height: 1000)){
    CookbookTunerView()

}
