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

let tuningModes: [TuningMode] = [.chromatic,.instrument]

let instruments: [Instrument] = [
    .Acoustic,
    .Electric,
    .Bass,
    .Ukulele
]
