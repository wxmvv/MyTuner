//
//  SettingsManager.swift
//  MyTuner
//
//  Created by wxm on 3/27/25.
//

let appIcons:[AppIcon] = [.icon1,.icon2]

let inTuneRangeValues : [Int] = [1,2,5,7,10]

let amplitudeLimitValues : [Double] = [0.01, 0.05, 0.075 , 0.1, 0.15, 0.2, 0.3, 0.4, 0.5]

let pitchStandardValues : [Int] = [415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460]

let smoothingFactorValues : [Double] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

let responseSpeedValues : [ResponseSpeed] = [
    // .shortest,
    // .veryShort,
    .short,
    .medium,
    .long,
    // .veryLong,
    // .huge,
    // .longest
]

let tuningModes = TuningMode.allCases

let instruments: [Instrument] = [
    .Acoustic,
    .Electric,
    .Bass,
    .Ukulele
]



let devAvailableInstruments = [
    // Acoustic Guitars
    InstrumentDefinition(displayName: "Acoustic Guitars", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 0),
    InstrumentDefinition(displayName: "Wet Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 1),
    InstrumentDefinition(displayName: "Dry Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 2),
    InstrumentDefinition(displayName: "Chorus Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 3),
    InstrumentDefinition(displayName: "Warm Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 4),
    InstrumentDefinition(displayName: "Warm Chorus", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 5),
    InstrumentDefinition(displayName: "Soft Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 6),
    InstrumentDefinition(displayName: "Octave Pad", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 7),
    InstrumentDefinition(displayName: "12 String Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 8),
    
    // Piano Piano_Z-Doc Soundfont II
    InstrumentDefinition(displayName: "Piano_Z-Doc Soundfont II", fileName: "Piano_Z-Doc Soundfont II", subdirectory: "Sampler", preset: 0, needsAutoStop: true, autoStopDelay: 2.0),
    
]

let proAvailableInstruments = [
    InstrumentDefinition(displayName: "Acoustic Guitars", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 0)
]

let defaultAvailableInstruments = [
    InstrumentDefinition(displayName: "Guitar", fileName: "Acoustic Guitars", subdirectory: "Sampler", preset: 0),
    InstrumentDefinition(displayName: "Piano", fileName: "Piano_Z-Doc Soundfont II", subdirectory: "Sampler", preset: 0, needsAutoStop: true, autoStopDelay: 2.0),
]





// CrisisSf2
//    InstrumentDefinition(displayName: "Music Box", fileName: "000_010 CrisisMusicBox", subdirectory: "Sounds/CrisisSf2", preset: 10, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Slap Bass", fileName: "000_037 CrisisSlapBass02", subdirectory: "Sounds/CrisisSf2", preset: 37, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Violin", fileName: "000_040 CrisisViolin", subdirectory: "Sounds/CrisisSf2", preset: 40, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Viola", fileName: "000_041 CrisisViola", subdirectory: "Sounds/CrisisSf2", preset: 41, bank: 0),
//    InstrumentDefinition(displayName: "Crisis SynthString01", fileName: "000_050 CrisisSynthString01", subdirectory: "Sounds/CrisisSf2", preset: 50, bank: 0),
//    InstrumentDefinition(displayName: "Crisis SynthString02", fileName: "000_050 CrisisSynthString01", subdirectory: "Sounds/CrisisSf2", preset: 50, bank: 0),
//    InstrumentDefinition(displayName: "Crisis SynthBrass02", fileName: "000_063 CrisisSynthBrass02", subdirectory: "Sounds/CrisisSf2", preset: 63, bank: 0),
//
//    InstrumentDefinition(displayName: "Crisis Square Wave", fileName: "000_080 CrisisSquareWave", subdirectory: "Sounds/CrisisSf2", preset: 80, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Saw Tooth", fileName: "000_081 CrisisSawTooth", subdirectory: "Sounds/CrisisSf2", preset: 81, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Calliope", fileName: "000_082 CrisisCalliope", subdirectory: "Sounds/CrisisSf2", preset: 82, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Fifths", fileName: "000_086 CrisisFifths", subdirectory: "Sounds/CrisisSf2", preset: 86, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Bass&Lead", fileName: "000_087 CrisisBass&Lead", subdirectory: "Sounds/CrisisSf2", preset: 87, bank: 0),
//    InstrumentDefinition(displayName: "Crisis PolysynthPad", fileName: "000_090 CrisisPolysynthPad", subdirectory: "Sounds/CrisisSf2", preset: 90, bank: 0),
//    InstrumentDefinition(displayName: "Crisis Soundtrack", fileName: "000_097 CrisisSoundtrack", subdirectory: "Sounds/CrisisSf2", preset: 97, bank: 0),
//


//    Triangle Wave
//    Sine Wave
//    Piano
//    Synthesizer
//    Marimba
//    Guitar
//    Cello
//    Flute
//    Flute(Vibrato)
//    Clarinet
//    Oboe
//    Saxophone
//    Trumpet
//    French Horn
//    Tuba

